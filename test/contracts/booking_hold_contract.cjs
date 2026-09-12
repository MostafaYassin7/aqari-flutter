// Run: node test/contracts/booking_hold_contract.cjs [path-to-aqari-backend]
// Executes actual backend services with an in-memory repository/manager seam.
// No network, database, payments or sibling-repository writes.
const assert = require('node:assert/strict');
const path = require('node:path');
const { createRequire } = require('node:module');
const backend = path.resolve(process.argv[2] || '../aqari-backend');
const backendRequire = createRequire(path.join(backend, 'package.json'));
backendRequire('ts-node').register({ project: path.join(backend, 'tsconfig.json'), transpileOnly: true });
const source = (file) => require(path.join(backend, 'src', file));
const { BookingsService } = source('modules/bookings/bookings.service.ts');
const { WalletService } = source('modules/wallet/wallet.service.ts');
const { Booking } = source('modules/bookings/entities/booking.entity.ts');
const { Listing } = source('modules/listings/entities/listing.entity.ts');
const { ListingAvailability } = source('modules/listings/entities/listing-availability.entity.ts');
const { Wallet } = source('modules/wallet/entities/wallet.entity.ts');
const { Transaction } = source('modules/wallet/entities/transaction.entity.ts');
const { BookingHold } = source('modules/wallet/entities/booking-hold.entity.ts');
const { Invoice } = source('modules/wallet/entities/invoice.entity.ts');
const rows = new Map();
const table = (entity) => { if (!rows.has(entity)) rows.set(entity, []); return rows.get(entity); };
let serial = 0;
function matches(row, where) {
  return Object.entries(where).every(([key, value]) => {
    if (value && typeof value === 'object' && value._type === 'in') return value._value.includes(row[key]);
    if (value && typeof value === 'object' && value._type === 'lessThanOrEqual') return row[key] <= value._value;
    return row[key] === value;
  });
}
const manager = {
  async findOne(entity, options) { return table(entity).find((row) => matches(row, options.where)) || null; },
  create(entity, values) {
    if (Array.isArray(values)) return values.map((value) => this.create(entity, value));
    return Object.assign(new entity(), { id: `contract-${++serial}` }, values);
  },
  async save(entityOrValue, values) {
    const value = values || entityOrValue;
    if (Array.isArray(value)) return Promise.all(value.map((v) => this.save(v)));
    const entity = values ? entityOrValue : value.constructor;
    const data = table(entity); const index = data.findIndex((r) => r.id === value.id);
    if (index < 0) data.push(value); else data[index] = value;
    return value;
  },
};
const dataSource = { transaction: async (fn) => fn(manager) };
const notifications = { createAndSend: async () => {} };
const holdsRepo = {
  find: async ({ where }) => table(BookingHold).filter((row) => matches(row, where)),
  createQueryBuilder: () => {
    let column, walletId, status;
    return {
      select() { return this; },
      where(expression, params) { column = expression.includes('guestWalletId') ? 'guestWalletId' : 'hostWalletId'; walletId = params.walletId; return this; },
      andWhere(_, params) { status = params.status; return this; },
      async getRawOne() { return { sum: table(BookingHold).filter((h) => h[column] === walletId && h.status === status).reduce((sum, h) => sum + Number(h.amount), 0).toFixed(2) }; },
    };
  },
};
async function main() {
  const guest = await manager.save(manager.create(Wallet, { id: 'guest-wallet', userId: 'guest', balance: '500.00', currency: 'SAR' }));
  const host = await manager.save(manager.create(Wallet, { id: 'host-wallet', userId: 'host', balance: '50.00', currency: 'SAR' }));
  await manager.save(manager.create(Listing, { id: 'listing', ownerId: 'host', propertyType: 'chalet', listingType: 'rent_short' }));
  const booking = await manager.save(manager.create(Booking, { id: 'booking', ownerId: 'host', guestId: 'guest', listingId: 'listing', status: 'pending', totalPrice: '200.00', checkInDate: '2026-09-10', checkOutDate: '2026-09-12' }));
  const bookings = new BookingsService({}, {}, {}, holdsRepo, dataSource, notifications);
  const wallets = new WalletService({ findOne: (options) => manager.findOne(Wallet, options) }, {}, {}, holdsRepo, dataSource, notifications);
  guest.balance = '100.00';
  await assert.rejects(() => bookings.confirmBooking('host', 'booking'), /رصيد الضيف/);
  assert.equal(booking.status, 'pending'); assert.equal(guest.balance, '100.00'); assert.equal(host.balance, '50.00');
  for (const entity of [Transaction, Invoice, BookingHold, ListingAvailability]) assert.equal(table(entity).length, 0);
  console.log('PASS insufficient funds: unchanged pending status, balances, transactions, invoices, holds and dates');
  guest.balance = '500.00';
  await bookings.confirmBooking('host', 'booking');
  assert.equal(booking.status, 'confirmed');
  assert.equal(table(Invoice).length, 1); assert.equal(table(Invoice)[0].transactionId, table(Transaction)[0].id);
  assert.equal(guest.balance, '300.00'); assert.equal(host.balance, '50.00');
  assert.equal(table(Transaction).length, 1); assert.equal(table(Transaction)[0].type, 'debit');
  assert.equal(table(Transaction)[0].referenceId, 'booking');
  assert.equal(table(BookingHold).length, 1); assert.equal(table(BookingHold)[0].status, 'held');
  assert.equal(table(ListingAvailability).length, 2);
  assert.equal((await wallets.getBalance('guest')).heldBalance, '200.00');
  assert.equal((await wallets.getBalance('host')).pendingEarnings, '200.00');
  console.log('PASS confirmation: one guest debit, one active hold, two booked nights, separate wallet summaries');
  await assert.rejects(() => bookings.confirmBooking('host', 'booking'));
  assert.equal(table(Transaction).length, 1); assert.equal(table(BookingHold).length, 1); assert.equal(guest.balance, '300.00');
  assert.equal(table(Invoice).length, 1); assert.equal(table(ListingAvailability).length, 2);
  console.log('PASS duplicate confirmation: no duplicate debit, invoice, hold or dates');
  table(BookingHold)[0].releaseAt = new Date(0);
  await bookings.releaseDueBookingHolds(); await bookings.releaseDueBookingHolds();
  assert.equal(host.balance, '250.00'); assert.equal(booking.status, 'completed');
  assert.equal(table(Transaction).filter((t) => t.type === 'credit').length, 1);
  assert.equal(table(BookingHold)[0].status, 'released');
  assert.equal(table(Invoice).length, 2);
  assert.equal(table(Invoice).filter((i) => i.userId === 'host').length, 1);
  assert.equal(table(Invoice).find((i) => i.userId === 'host').transactionId, table(Transaction).find((t) => t.type === 'credit').id);
  assert.equal((await wallets.getBalance('host')).pendingEarnings, '0.00');
  assert.equal((await wallets.getBalance('guest')).heldBalance, '0.00');
  console.log('PASS forced-due release: one host credit, cleared holds/pending earnings, completed booking');
}
main().catch((error) => { console.error(error); process.exitCode = 1; });
