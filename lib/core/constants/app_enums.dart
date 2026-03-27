// Enum values verified directly from Swagger at /api/docs-json
// UserRole is UPPERCASE — all others are lowercase snake_case

class UserRole {
  UserRole._();
  // Confirmed from CompleteProfileDto.role enum in Swagger
  static const user   = 'USER';
  static const owner  = 'OWNER';
  static const broker = 'BROKER';
  static const host   = 'HOST';
}

class PropertyType {
  PropertyType._();
  // Confirmed from CreateListingDto.propertyType enum in Swagger
  static const apartment        = 'apartment';
  static const villa            = 'villa';
  static const floor            = 'floor';
  static const land             = 'land';
  static const building         = 'building';
  static const shop             = 'shop';
  static const house            = 'house';
  static const restHouse        = 'rest_house';
  static const farm             = 'farm';
  static const commercialOffice = 'commercial_office';
  static const chalet           = 'chalet';
  static const warehouse        = 'warehouse';
  static const camp             = 'camp';
  static const other            = 'other';
}

class ListingType {
  ListingType._();
  // Confirmed from CreateListingDto.listingType enum in Swagger
  static const sale      = 'sale';
  static const rentLong  = 'rent_long';
  static const rentShort = 'rent_short';
}

class ListingStatus {
  ListingStatus._();
  // Confirmed from UpdateStatusDto.status enum in Swagger
  static const published  = 'published';
  static const pausedTemp = 'paused_temp';
  static const paused     = 'paused';
  static const expired    = 'expired';
  static const pending    = 'pending';
}

class UsageType {
  UsageType._();
  // Confirmed from CreateListingDto.usageType enum in Swagger
  static const residential = 'residential';
  static const commercial  = 'commercial';
}

class Facade {
  Facade._();
  // Confirmed from CreateListingDto.facade enum in Swagger
  static const north     = 'north';
  static const south     = 'south';
  static const east      = 'east';
  static const west      = 'west';
  static const northeast = 'northeast';
  static const northwest = 'northwest';
  static const southeast = 'southeast';
  static const southwest = 'southwest';
}

class ProjectStatus {
  ProjectStatus._();
  // Confirmed from CreateProjectDto.status enum in Swagger
  static const ready   = 'ready';
  static const offPlan = 'off_plan';
}

class UnitType {
  UnitType._();
  // Confirmed from CreateUnitDto.unitType enum in Swagger
  static const studio     = 'studio';
  static const oneBr      = '1br';
  static const twoBr      = '2br';
  static const threeBr    = '3br';
  static const fourBr     = '4br';
  static const villa      = 'villa';
  static const commercial = 'commercial';
}

class UnitAvailability {
  UnitAvailability._();
  // Confirmed from CreateUnitDto.availability enum in Swagger
  static const available = 'available';
  static const sold      = 'sold';
  static const reserved  = 'reserved';
}

class ClientPriority {
  ClientPriority._();
  // Confirmed from CreateClientDto.priority enum in Swagger
  static const high   = 'high';
  static const medium = 'medium';
  static const low    = 'low';
}

class EngagementTarget {
  EngagementTarget._();
  // Confirmed from ToggleFavoriteDto.targetType enum in Swagger
  static const listing = 'listing';
  static const project = 'project';
}

class ReportTargetType {
  ReportTargetType._();
  // Confirmed from CreateReportDto.targetType enum in Swagger
  static const listing = 'listing';
  static const user    = 'user';
}

class ReportReason {
  ReportReason._();
  // Confirmed from CreateReportDto.reason enum in Swagger
  static const spam          = 'spam';
  static const fraud         = 'fraud';
  static const inappropriate = 'inappropriate';
  static const duplicate     = 'duplicate';
  static const other         = 'other';
}

class RatingReferenceType {
  RatingReferenceType._();
  // Confirmed from CreateRatingDto.referenceType enum in Swagger
  static const booking = 'booking';
  static const deal    = 'deal';
}

// Not in Swagger DTOs — inferred from backend contract
class BookingType {
  BookingType._();
  static const daily   = 'daily';
  static const monthly = 'monthly';
}

class BookingStatus {
  BookingStatus._();
  static const pending   = 'pending';
  static const confirmed = 'confirmed';
  static const declined  = 'declined';
  static const expired   = 'expired';
  static const cancelled = 'cancelled';
  static const completed = 'completed';
}

class TransactionType {
  TransactionType._();
  static const credit = 'credit';
  static const debit  = 'debit';
}

class NotificationType {
  NotificationType._();
  static const newMessage       = 'new_message';
  static const bookingUpdate    = 'booking_update';
  static const listingApproved  = 'listing_approved';
  static const listingExpired   = 'listing_expired';
  static const searchAlert      = 'search_alert';
  static const paymentConfirmed = 'payment_confirmed';
  static const newRating        = 'new_rating';
  static const system           = 'system';
}

class BundleCode {
  BundleCode._();
  static const basic  = 'basic';
  static const bronze = 'bronze';
  static const silver = 'silver';
  static const golden = 'golden';
}

class SubscriptionStatus {
  SubscriptionStatus._();
  static const active    = 'active';
  static const expired   = 'expired';
  static const cancelled = 'cancelled';
}
