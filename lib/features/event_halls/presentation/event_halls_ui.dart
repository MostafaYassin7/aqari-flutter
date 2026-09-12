import 'providers/hall_filters.dart';
import 'providers/event_halls_provider.dart';
import '../domain/hall_contact.dart';
import '../../home/data/listings_repository.dart';
import '../../../core/network/api_failure.dart';
import '../../../shared/domain/property_rules.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../home/presentation/widgets/country_chips_row.dart';
import '../../search/presentation/widgets/search_filter_sheet.dart';
import '../../home/presentation/providers/home_provider.dart'
    show cityArabicNames;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/preview/ui_preview.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/listing.dart';
import '../../home/presentation/widgets/listing_card.dart';
import '../../property_details/presentation/widgets/photo_gallery_viewer.dart';

class EventHallPreview {
  final Listing listing;
  final int? capacity;
  final double? halfDay;
  final List<String> services;
  const EventHallPreview(
    this.listing, {
    required this.capacity,
    this.halfDay,
    this.services = const [],
  });
}

final eventHallsPreviewProvider = Provider<List<EventHallPreview>>(
  (ref) => [
    for (var i = 0; i < 4; i++)
      EventHallPreview(
        Listing(
          id: 'hall-$i',
          title: [
            'قاعة ليالي',
            'قاعة الياسمين',
            'قاعة النخيل',
            'قاعة الورد',
          ][i],
          city: i.isEven ? 'الرياض' : 'جدة',
          district: 'حي النزهة',
          category: 'قاعة مناسبات',
          propertyType: 'event_hall',
          listingType: 'rent_short',
          price: 3500 + i * 1000,
          area: 400 + i * 150,
          bedrooms: 0,
          bathrooms: 0,
          livingRooms: 0,
          description:
              'قاعة واسعة للمناسبات والأفراح، مع جلسات أنيقة وخدمات ضيافة متكاملة. تواصل مع المضيف لترتيب مناسبتك.',
          imageUrls: [
            'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=1000',
            'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=1000',
          ],
          ownerName: 'إدارة القاعة',
          lat: 24.7136 + i * .01,
          lng: 46.6753 + i * .01,
        ),
        capacity: 150 + i * 100,
        halfDay: i.isEven ? 2200 + i * 500 : null,
        services: ['ضيافة وطعام', 'نظام صوتي', 'ديكور', 'مواقف سيارات'],
      ),
  ],
);

void showHallFilters(BuildContext context) {
  final container = ProviderScope.containerOf(context);
  final f = container.read(hallFiltersProvider);
  showSearchFilterSheet(
    context,
    showPropertyFields: false,
    initialValues: SearchFilterValues(
      priceFrom: f.min,
      priceTo: f.max,
      areaFrom: f.areaFrom,
      areaTo: f.areaTo,
    ),
    onApply: (v) => container
        .read(hallFiltersProvider.notifier)
        .set(
          HallFilters(
            city: f.city,
            min: v.priceFrom,
            max: v.priceTo,
            areaFrom: v.areaFrom,
            areaTo: v.areaTo,
          ),
        ),
  );
}

class EventHallsTab extends ConsumerStatefulWidget {
  const EventHallsTab({super.key});
  @override
  ConsumerState<EventHallsTab> createState() => _EventHallsTabState();
}

class _EventHallsTabState extends ConsumerState<EventHallsTab> {
  bool map = false;
  String view = 'data';
  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(hallFiltersProvider);
    final live = uiPreview ? null : ref.watch(eventHallsProvider);
    final all = uiPreview
        ? ref.watch(eventHallsPreviewProvider)
        : [
            for (final h in live?.value?.listings ?? <Listing>[])
              EventHallPreview(
                h,
                capacity: h.maxGuests,
                halfDay: h.pricePerHalfDay,
                services: h.includedServices.map(includedServiceLabel).toList(),
              ),
          ];
    final halls = all
        .where(
          (h) =>
              (filters.city.isEmpty ||
                  h.listing.city == filters.city ||
                  h.listing.city ==
                      (cityArabicNames[filters.city] ?? filters.city)) &&
              h.listing.price >= (filters.min ?? 0) &&
              h.listing.price <= (filters.max ?? double.infinity) &&
              h.listing.area >= (filters.areaFrom ?? 0) &&
              h.listing.area <= (filters.areaTo ?? double.infinity),
        )
        .toList();
    return Column(
      children: [
        CountryChipsRow.controlled(
          currentCity: filters.city.isEmpty ? null : filters.city,
          onCityChanged: (city) => ref
              .read(hallFiltersProvider.notifier)
              .set(
                HallFilters(
                  city: city ?? '',
                  min: filters.min,
                  max: filters.max,
                  areaFrom: filters.areaFrom,
                  areaTo: filters.areaTo,
                ),
              ),
        ),
        Divider(height: 1, color: context.appColors.divider),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              '${halls.length} قاعات',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ),
        if (uiPreview)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const PreviewNotice(),
              PopupMenuButton<String>(
                tooltip: 'حالات المعاينة',
                onSelected: (v) => setState(() => view = v),
                itemBuilder: (_) => [
                  for (final e in {
                    'data': 'البيانات',
                    'loading': 'تحميل',
                    'error': 'خطأ',
                    'empty': 'فارغ',
                  }.entries)
                    PopupMenuItem(value: e.key, child: Text(e.value)),
                ],
              ),
            ],
          ),
        Expanded(
          child: Stack(
            children: [
              if (view == 'loading' || live?.isLoading == true)
                const Center(child: CircularProgressIndicator())
              else if (view == 'error' || live?.hasError == true)
                Center(
                  child: TextButton(
                    onPressed: () {
                      if (!uiPreview) ref.invalidate(eventHallsProvider);
                      setState(() => view = 'data');
                    },
                    child: const Text('تعذر عرض القاعات · إعادة المحاولة'),
                  ),
                )
              else if (halls.isEmpty || view == 'empty')
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.celebration_outlined,
                        size: 56,
                        color: context.appColors.icon,
                      ),
                      const SizedBox(height: 12),
                      const Text('لا توجد قاعات تطابق بحثك'),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(hallFiltersProvider.notifier)
                              .set(const HallFilters());
                          setState(() => view = 'data');
                        },
                        child: const Text('مسح الفلاتر'),
                      ),
                    ],
                  ),
                )
              else if (map && !uiPreview)
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: halls.any((h) => h.listing.hasCoordinates)
                        ? LatLng(
                            halls
                                .firstWhere((h) => h.listing.hasCoordinates)
                                .listing
                                .lat,
                            halls
                                .firstWhere((h) => h.listing.hasCoordinates)
                                .listing
                                .lng,
                          )
                        : const LatLng(24.7136, 46.6753),
                    zoom: 9,
                  ),
                  markers: {
                    for (final hall in halls)
                      if (hall.listing.hasCoordinates)
                        Marker(
                          markerId: MarkerId(hall.listing.id),
                          position: LatLng(hall.listing.lat, hall.listing.lng),
                          infoWindow: InfoWindow(
                            title: hall.listing.title,
                            snippet: '${hall.listing.price} ريال',
                            onTap: () =>
                                context.push('/event-halls/${hall.listing.id}'),
                          ),
                        ),
                  },
                )
              else if (map)
                SampleMap(
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 40,
                    children: halls
                        .map<Widget>(
                          (h) => ActionChip(
                            label: Text('${h.listing.price.toInt()} ريال'),
                            onPressed: () =>
                                context.push('/event-halls/${h.listing.id}'),
                          ),
                        )
                        .toList(),
                  ),
                )
              else
                RefreshIndicator(
                  onRefresh: () async {
                    if (!uiPreview) {
                      await ref.read(eventHallsProvider.notifier).refresh();
                    }
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 12, bottom: 80),
                    children:
                        halls
                            .map<Widget>(
                              (h) => ListingCard(
                                listing: h.listing,
                                onTap: () => context.push(
                                  '/event-halls/${h.listing.id}',
                                ),
                                statsLabel:
                                    '${h.capacity == null ? '' : '${h.capacity} ضيف · '}${h.listing.area} م²',
                                priceSuffix: ' / يوم',
                              ),
                            )
                            .toList()
                          ..addAll([
                            if (live?.value?.hasMore == true)
                              TextButton(
                                onPressed: live?.value?.loadingMore == true
                                    ? null
                                    : () => ref
                                          .read(eventHallsProvider.notifier)
                                          .loadMore(),
                                child: Text(
                                  live?.value?.pageError ?? 'عرض المزيد',
                                ),
                              ),
                          ]),
                  ),
                ),
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: FilledButton.icon(
                    onPressed: () => setState(() => map = !map),
                    icon: Icon(map ? Icons.list : Icons.map_outlined),
                    label: Text(map ? 'القائمة' : 'الخريطة'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EventHallDetailsScreen extends ConsumerStatefulWidget {
  final String id;
  const EventHallDetailsScreen({super.key, required this.id});
  @override
  ConsumerState<EventHallDetailsScreen> createState() =>
      _EventHallDetailsScreenState();
}

class _EventHallDetailsScreenState
    extends ConsumerState<EventHallDetailsScreen> {
  bool _contactBusy = false;
  Future<void> _contact(Listing listing, {bool whatsApp = false}) async {
    if (_contactBusy) return;
    _contactBusy = true;
    try {
      if (whatsApp) {
        final uri = whatsAppUri(listing.owner?.phone, title: listing.title);
        if (uri == null) throw const ApiFailure('رقم جوال المعلن غير متاح.');
        if (!await ref.read(externalLinkLauncherProvider)(uri)) {
          throw const ApiFailure('تعذر فتح واتساب.');
        }
      } else {
        if (listing.contactOwnerId.isEmpty) {
          throw const ApiFailure('بيانات المعلن غير متاحة.');
        }
        final id = await ref.read(hallChatStarterProvider)(
          listing.contactOwnerId,
          listing.id,
        );
        if (mounted) context.push('/chat/$id');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiFailure.fromError(e).message)),
        );
      }
    } finally {
      _contactBusy = false;
    }
  }

  bool favorite = false;
  int photo = 0;
  @override
  Widget build(BuildContext context) {
    final live = uiPreview ? null : ref.watch(hallDetailProvider(widget.id));
    if (live?.isLoading == true) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (live?.hasError == true) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: TextButton(
            onPressed: () => ref.invalidate(hallDetailProvider(widget.id)),
            child: Text(
              '${ApiFailure.fromError(live!.error!).message} · إعادة المحاولة',
            ),
          ),
        ),
      );
    }
    final fixture = uiPreview
        ? ref
              .watch(eventHallsPreviewProvider)
              .where((h) => h.listing.id == widget.id)
              .firstOrNull
        : null;
    final item = live?.value;
    if ((!uiPreview && (item == null || !item.rules.isEventHall)) ||
        (uiPreview && fixture == null)) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('القاعة غير موجودة')),
      );
    }
    final hall =
        fixture ??
        EventHallPreview(
          item!,
          capacity: item.maxGuests,
          halfDay: item.pricePerHalfDay,
          services: item.includedServices.map(includedServiceLabel).toList(),
        );
    final h = hall.listing;
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 290,
            pinned: true,
            backgroundColor: context.appColors.card,
            actions: [
              IconButton(
                onPressed: () async {
                  if (uiPreview) {
                    setState(() => favorite = !favorite);
                    return;
                  }
                  try {
                    await ListingsRepository().toggleFavorite(targetId: h.id);
                    if (mounted) setState(() => favorite = !favorite);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ApiFailure.fromError(e).message),
                        ),
                      );
                    }
                  }
                },
                icon: Icon(
                  favorite ? Icons.favorite : Icons.favorite_border,
                  color: favorite
                      ? AppColors.error
                      : context.appColors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () => uiPreview
                    ? previewResult(context, 'معاينة المشاركة', h.title)
                    : SharePlus.instance.share(
                        ShareParams(
                          text:
                              '${h.title} https://aqora.sa/ar/event-halls/${h.id}',
                        ),
                      ),
                icon: const Icon(Icons.ios_share),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: GestureDetector(
                onTap: () => showPhotoGallery(
                  context: context,
                  imageUrls: h.imageUrls,
                  initialIndex: photo,
                ),
                child: PageView(
                  onPageChanged: (i) => setState(() => photo = i),
                  children: h.imageUrls
                      .map(
                        (url) => Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stack) => ColoredBox(
                            color: context.appColors.surface,
                            child: Icon(
                              Icons.celebration_outlined,
                              size: 72,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList.list(
              children: [
                Text(h.title, style: AppTextStyles.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  '${h.city} · ${h.district}',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 20),
                Text(
                  '${hall.capacity == null ? '' : '${hall.capacity} ضيف · '}${h.area} م²',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 20),
                PreviewSection(
                  title: 'أسعار القاعة',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${h.price.toInt()} ريال / يوم كامل',
                        style: AppTextStyles.titleLarge,
                      ),
                      if (hall.halfDay != null)
                        Text(
                          '${hall.halfDay!.toInt()} ريال / نصف يوم',
                          style: AppTextStyles.bodyMedium,
                        ),
                    ],
                  ),
                ),
                if (hall.services.isNotEmpty)
                  PreviewSection(
                    title: 'الخدمات المشمولة',
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: hall.services
                          .map(
                            (s) => Chip(
                              avatar: const Icon(
                                Icons.check,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              label: Text(s),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                PreviewSection(
                  title: 'عن القاعة',
                  child: Text(h.description, style: AppTextStyles.bodyMedium),
                ),
                if (uiPreview || h.hasCoordinates)
                  PreviewSection(
                    title: 'الموقع',
                    child: SizedBox(
                      height: 170,
                      child: !uiPreview
                          ? GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(h.lat, h.lng),
                                zoom: 14,
                              ),
                              zoomControlsEnabled: false,
                              markers: {
                                Marker(
                                  markerId: const MarkerId('hall'),
                                  position: LatLng(h.lat, h.lng),
                                ),
                              },
                            )
                          : SampleMap(
                              child: const Icon(
                                Icons.location_pin,
                                size: 44,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: context.appColors.primaryTint,
                    child: Icon(Icons.person_outline, color: AppColors.primary),
                  ),
                  title: Text(h.ownerName, style: AppTextStyles.titleMedium),
                  subtitle: const Text('تواصل لترتيب الموعد والتفاصيل'),
                ),
                const PreviewNotice(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: context.appColors.card,
            border: Border(top: BorderSide(color: context.appColors.divider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: !uiPreview
                      ? () => _contact(h, whatsApp: true)
                      : () => previewResult(
                          context,
                          'معاينة التواصل عبر واتساب',
                          'في الخدمة الكاملة يمكنك التواصل مع إدارة القاعة لترتيب المناسبة. لم يتم فتح محادثة خارجية.',
                        ),
                  child: const Text('واتساب'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => uiPreview
                      ? context.push('/preview-conversation')
                      : _contact(h),
                  child: const Text('تواصل'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SampleMap extends StatelessWidget {
  final Widget child;
  const SampleMap({super.key, required this.child});
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _MapGrid(context.appColors),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      alignment: Alignment.center,
      child: child,
    ),
  );
}

class _MapGrid extends CustomPainter {
  final AppPalette colors;
  _MapGrid(this.colors);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.surface);
    final p = Paint()
      ..color = colors.divider
      ..strokeWidth = 10;
    for (double x = -size.height; x < size.width; x += 65) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), p);
    }
    for (double y = 0; y < size.height; y += 55) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _MapGrid oldDelegate) =>
      colors.brightness != oldDelegate.colors.brightness;
}

final hallDetailProvider = FutureProvider.family<Listing, String>(
  (ref, id) => ListingsRepository().getListingById(id),
);
