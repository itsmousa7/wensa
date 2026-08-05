// Bilingual dictionary and language engine.
//
// Arabic is the default and is what the server sends. The toggle swaps text
// in place rather than navigating, so there is no reload and no flash. A tiny
// inline snippet in each page's <head> applies the stored choice before first
// paint; this module handles everything after that.
//
// Copy rules (WENSA_BRAND_SKILL.md §9): Iraqi dialect, never فصحى.
// Arabic-Indic numerals ٠١٢٣٤٥٦٧٨٩ in Arabic copy. Currency د.ع / IQD.

export const dict = {
  ar: {
    "nav.what": "شنو ونسة",
    "nav.places": "الاماكن",
    "nav.download": "نزّل التطبيق",
    "nav.merchant": "صير تاجر بونسة",
    "nav.langToggle": "English",
    "nav.skip": "روح للمحتوى",
    "footer.privacy": "سياسة الخصوصية",
    "footer.download": "نزّل التطبيق",
    "footer.merchant": "صير تاجر",
    "footer.rights": "كل الحقوق محفوظة",
    "footer.tagline": "كل ونستك بمكان واحد",
    "merchant.ctaRegister": "سجّل هسه",
    "hero.eyebrow": "نزل هسه — مجاناً",
    "hero.lead": "احجز",
    "hero.trail": "بثانية وحدة",
    "hero.sub": "مطاعم، ملاعب، مزارع وحفلات — كلها بتطبيق واحد. شوف، احجز، وادفع بالدينار، وتذكرتك تجيك QR.",
    "hero.ios": "نزّله من App Store",
    "hero.android": "نزّله من Google Play",
    // The nine categories the app's home screen actually renders — see
    // lib/features/home/presentation/widgets/category_bar.dart. Do not add a
    // category here that the app does not have.
    "cat.sports": "رياضة",
    "cat.restaurants": "مطاعم",
    "cat.music": "موسيقى",
    "cat.malls": "مولات",
    "cat.cafes": "كافيهات",
    "cat.cinema": "سينما",
    "cat.festivals": "مهرجانات",
    "cat.farms": "مزارع",
    "cat.discounts": "خصومات",
    "ticker.label": "شنو تلگه بونسة",
  },
  en: {
    "nav.what": "What is Wensa",
    "nav.places": "Places",
    "nav.download": "Get the app",
    "nav.merchant": "Become a merchant",
    "nav.langToggle": "عربي",
    "nav.skip": "Skip to content",
    "footer.privacy": "Privacy Policy",
    "footer.download": "Get the app",
    "footer.merchant": "Become a merchant",
    "footer.rights": "All rights reserved",
    "footer.tagline": "Everything you do, in one place",
    "merchant.ctaRegister": "Register now",
    "hero.eyebrow": "Out now — free",
    "hero.lead": "Book",
    "hero.trail": "in one second",
    "hero.sub": "Restaurants, courts, farms and concerts — all in one app. Browse, book, pay in IQD, and get a QR ticket.",
    "hero.ios": "Download on the App Store",
    "hero.android": "Get it on Google Play",
    "cat.sports": "Sports",
    "cat.restaurants": "Restaurants",
    "cat.music": "Music",
    "cat.malls": "Malls",
    "cat.cafes": "Cafes",
    "cat.cinema": "Cinema",
    "cat.festivals": "Festivals",
    "cat.farms": "Farms",
    "cat.discounts": "Discounts",
    "ticker.label": "What you'll find on Wensa",
  },
};

// The words that cycle inside the hero headline. Both arrays must stay the
// same length so the cycle reads identically in either language.
export const ROTATIONS = {
  ar: ["بادل", "مطعم", "مزرعة", "حفلة", "جم"],
  en: ["padel", "a table", "a farm", "a concert", "a gym"],
};

const STORAGE_KEY = "wensa_lang";

export function currentLang() {
  return document.documentElement.lang === "en" ? "en" : "ar";
}

export function applyLang(lang) {
  const safe = lang === "en" ? "en" : "ar";
  const table = dict[safe];

  document.documentElement.lang = safe;
  document.documentElement.dir = safe === "ar" ? "rtl" : "ltr";

  for (const el of document.querySelectorAll("[data-i18n]")) {
    const value = table[el.dataset.i18n];
    if (value !== undefined) el.textContent = value;
  }

  // data-i18n-attr="aria-label:nav.merchant" — key writes into a named attribute
  // rather than textContent, for labels, alt text, and titles.
  for (const el of document.querySelectorAll("[data-i18n-attr]")) {
    for (const pair of el.dataset.i18nAttr.split(",")) {
      const [attr, key] = pair.split(":").map((s) => s.trim());
      const value = table[key];
      if (value !== undefined) el.setAttribute(attr, value);
    }
  }

  try {
    localStorage.setItem(STORAGE_KEY, safe);
  } catch {
    // Private browsing can throw on write. The language still applies for
    // this pageview; only persistence is lost, which is not worth failing on.
  }

  const url = new URL(location.href);
  if (safe === "ar") url.searchParams.delete("lang");
  else url.searchParams.set("lang", "en");
  history.replaceState(null, "", url);

  document.dispatchEvent(new CustomEvent("wensa:langchange", { detail: { lang: safe } }));
}

export function initLangToggle() {
  for (const btn of document.querySelectorAll("[data-lang-toggle]")) {
    btn.addEventListener("click", () => {
      applyLang(currentLang() === "ar" ? "en" : "ar");
    });
  }
}
