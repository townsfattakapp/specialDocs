# Dual-Channel Consumer Strategy Rule

This rule governs the separation of mobile and web consumer experiences to balance legal compliance and average order value (AOV).

## 1. Compliance Background
- Google Play Store and Apple App Store policies strictly prohibit the sale and in-app purchase of tobacco, nicotine, and smoking products.
- Indian law (COTPA 2003) mandates strict age gating (18+) and prohibits the display and sale of tobacco products to minors.

## 2. Channel Segmentation
1. **Flutter Mobile Apps (`X-Client-Type: flutter-mobile`):**
   - **100% Tobacco-Free:** Must NEVER return or display any item classified under Module 4 (Paan Corner), category `tobacco`, or item tags `cigarette`, `bidi`, `tobacco`, `gutkha`.
   - The `api-gateway` acts as a compliance firewall: If a request originates from Flutter mobile, Paan Corner module and items are strictly suppressed from all catalog, category, search, and cart responses.

2. **React User Web App (`apps/user-web` at `fattakse.in`):**
   - **Full-Catalog Storefront:** Sells groceries, dark-store FMCG essentials, restaurant food, AND Paan Corner products.
   - Maximizes customer basket size and AOV by allowing consumers to combine tobacco with general groceries in a single checkout.
   - **COTPA 18+ Age Gate:** Web portal must display a non-bypassable 18+ age verification modal before entering the Paan Corner section or adding age-restricted items to cart.
   - Order flags: Sets `requires_age_verification: true` on order creation for orders containing tobacco items, triggering mandatory physical photo-ID check by the delivery rider at the customer doorstep.
