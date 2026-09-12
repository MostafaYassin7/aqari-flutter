// Preview records matching the category seed and Event Hall migration.
class ListingCategoryOption {
  final String label, propertyType, listingType;
  const ListingCategoryOption(this.label, this.propertyType, this.listingType);
  String get id => 'preview-$propertyType-$listingType';
}

const listingCategoryOptions = [
  ListingCategoryOption("شقة للبيع", "apartment", "sale"),
  ListingCategoryOption("شقة للإيجار", "apartment", "rent_long"),
  ListingCategoryOption("شقة إيجار يومي", "apartment", "rent_short"),
  ListingCategoryOption("فيلا للبيع", "villa", "sale"),
  ListingCategoryOption("فيلا للإيجار", "villa", "rent_long"),
  ListingCategoryOption("فيلا إيجار يومي", "villa", "rent_short"),
  ListingCategoryOption("دور للبيع", "floor", "sale"),
  ListingCategoryOption("دور للإيجار", "floor", "rent_long"),
  ListingCategoryOption("أرض للبيع", "land", "sale"),
  ListingCategoryOption("أرض للإيجار", "land", "rent_long"),
  ListingCategoryOption("عمارة للبيع", "building", "sale"),
  ListingCategoryOption("عمارة للإيجار", "building", "rent_long"),
  ListingCategoryOption("محل للبيع", "shop", "sale"),
  ListingCategoryOption("محل للإيجار", "shop", "rent_long"),
  ListingCategoryOption("بيت للبيع", "house", "sale"),
  ListingCategoryOption("بيت للإيجار", "house", "rent_long"),
  ListingCategoryOption("استراحة للبيع", "rest_house", "sale"),
  ListingCategoryOption("استراحة للإيجار", "rest_house", "rent_long"),
  ListingCategoryOption("استراحة إيجار يومي", "rest_house", "rent_short"),
  ListingCategoryOption("مزرعة للبيع", "farm", "sale"),
  ListingCategoryOption("مزرعة للإيجار", "farm", "rent_long"),
  ListingCategoryOption("مكتب للبيع", "commercial_office", "sale"),
  ListingCategoryOption("مكتب للإيجار", "commercial_office", "rent_long"),
  ListingCategoryOption("شاليه للبيع", "chalet", "sale"),
  ListingCategoryOption("شاليه إيجار يومي", "chalet", "rent_short"),
  ListingCategoryOption("مستودع للبيع", "warehouse", "sale"),
  ListingCategoryOption("مستودع للإيجار", "warehouse", "rent_long"),
  ListingCategoryOption("مخيم للبيع", "camp", "sale"),
  ListingCategoryOption("مخيم للإيجار", "camp", "rent_long"),
  ListingCategoryOption("قاعة مناسبات واحتفالات", "event_hall", "rent_short"),
];
