export type StorePackageCategory = "chips" | "gems" | "bundle";

export interface StoreCatalogPackage {
  package_id: string;
  category: StorePackageCategory;
  title: string;
  subtitle: string;
  chips_amount: number;
  gems_amount: number;
  badge: string;
  image_key: string;
  base_price_minor: number;
  base_currency: "USD";
  display_price: string;
  enabled: boolean;
  sort_order: number;
}

const STORE_CATALOG: readonly StoreCatalogPackage[] = [
  storePack("starter_pack", "Starter Pack", 20_000, 100, 199, "START HERE", 10),
  storePack("club_pack", "Club Pack", 60_000, 400, 499, "POPULAR", 20),
  storePack("pro_pack", "Pro Pack", 150_000, 1_000, 999, "GREAT VALUE", 30),
  storePack("high_roller_pack", "High Roller Pack", 350_000, 2_500, 1_999, "BEST VALUE", 40),
];

export function storeCatalog(): StoreCatalogPackage[] {
  return STORE_CATALOG.filter((item) => item.enabled)
    .slice()
    .sort((left, right) => left.sort_order - right.sort_order)
    .map((item) => ({ ...item }));
}

export function findStorePackage(packageId: string): StoreCatalogPackage | undefined {
  const item = STORE_CATALOG.find((candidate) => candidate.package_id === packageId);
  return item ? { ...item } : undefined;
}

function storePack(
  packageId: string,
  title: string,
  chipsAmount: number,
  gemsAmount: number,
  basePriceMinor: number,
  badge: string,
  sortOrder: number,
): StoreCatalogPackage {
  return {
    package_id: packageId,
    category: "bundle",
    title,
    subtitle: "Chips and Gems delivered together after Steam authorization.",
    chips_amount: chipsAmount,
    gems_amount: gemsAmount,
    badge,
    image_key: packageId,
    base_price_minor: basePriceMinor,
    base_currency: "USD",
    display_price: `$${(basePriceMinor / 100).toFixed(2)} USD`,
    enabled: true,
    sort_order: sortOrder,
  };
}
