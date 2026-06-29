export interface AvatarCatalogItem {
  avatar_id: string;
  display_name: string;
  price_chips: number;
  price_gems: number;
  currency: "chips" | "gems" | "free";
  is_default: boolean;
}

export const AVATAR_CATALOG: AvatarCatalogItem[] = [
  { avatar_id: "default", display_name: "Default Avatar", price_chips: 0, price_gems: 0, currency: "free", is_default: true },
  { avatar_id: "1_01", display_name: "Neon Phantom", price_chips: 1500, price_gems: 0, currency: "chips", is_default: false },
  { avatar_id: "1_02", display_name: "Cyber Dealer", price_chips: 2500, price_gems: 0, currency: "chips", is_default: false },
  { avatar_id: "1_03", display_name: "Violet Shark", price_chips: 0, price_gems: 15, currency: "gems", is_default: false },
  { avatar_id: "2_01", display_name: "Golden Ace", price_chips: 3500, price_gems: 0, currency: "chips", is_default: false },
  { avatar_id: "3_01", display_name: "Shadow Player", price_chips: 0, price_gems: 25, currency: "gems", is_default: false },
  { avatar_id: "7_01", display_name: "Crimson Queen", price_chips: 5000, price_gems: 0, currency: "chips", is_default: false },
  { avatar_id: "8_01", display_name: "Desert Gambler", price_chips: 0, price_gems: 40, currency: "gems", is_default: false },
  { avatar_id: "10_03", display_name: "Midnight Rider", price_chips: 7500, price_gems: 0, currency: "chips", is_default: false },
];

export function findAvatarCatalogItem(avatarId: string): AvatarCatalogItem | undefined {
  return AVATAR_CATALOG.find((item) => item.avatar_id === avatarId);
}
