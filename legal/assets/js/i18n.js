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
    "merchant.eyebrow": "لأصحاب الاماكن",
    "merchant.title": "خلي مكانك يوصل لكل بغداد",
    "merchant.sub": "اضم مكانك لونسة واستقبل حجوزات من التطبيق — بدون تلفونات وبدون دفتر حجوزات.",
    "merchant.ctaPricing": "شوف الاسعار",
    "offer.badge": "عرض",
    "offer.title": "اول شهر برو مجاناً + ٠٪ عمولة",
    "offer.body": "اول شهر الك على خطة برو كاملة، وماناخذ ولا فلس عمولة بيه.",
    "offer.fine": "بعد الشهر الاول، برو ٦٠٬٠٠٠ د.ع بالشهر وتنطبق العمولة الاعتيادية.",
    "offer.free": "وتبقى خطة اساسي مجانية دائماً — ماكو احد مجبور يدفع.",
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
    "what.title": "شنو تكدر تسوي بونسة؟",
    "what.c1.title": "دور وشوف",
    "what.c1.body": "كل الاماكن الحلوة ببغداد بمكان واحد — صور، دوام، تقييمات، وموقع.",
    "what.c2.title": "احجز بثانية",
    "what.c2.body": "طاولة، ملعب، شاليه او تذكرة حفلة — احجز وانت كاعد وادفع بالدينار.",
    "what.c3.title": "تذكرتك QR",
    "what.c3.body": "تذكرتك تجيك بالتطبيق. وريها عالباب وخلص — ماكو ورق وماكو لخبطة.",
    "how.title": "شلون تشتغل؟",
    "how.s1.title": "نزّل التطبيق",
    "how.s1.body": "مجاني على iOS و Android.",
    "how.s2.title": "اختار مكانك",
    "how.s2.body": "دور حسب النوع، المنطقة، او التقييم.",
    "how.s3.title": "احجز وروح",
    "how.s3.body": "ادفع بالدينار وتذكرتك تجيك QR.",
    "trust.iqd": "دفع بالدينار",
    "trust.qr": "تذكرة QR",
    "trust.cancel": "إلغاء سهل",
    "num.1": "١",
    "num.2": "٢",
    "num.3": "٣",
    "dl.title": "نزّل ونسة وابدا",
    "dl.body": "مجاني، وبالعربي، ومصمم للعراق. نزّله وشوف شنو اكو هاي الليلة.",
    "dl.qr": "صوّر الكود بكاميرتك",
    "band.title": "عندك مطعم او ملعب؟",
    "band.body": "اول شهر علينا — برو مجاناً و٠٪ عمولة.",
    "band.cta": "صير تاجر بونسة",
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
    "merchant.eyebrow": "For venue owners",
    "merchant.title": "Put your venue in front of all Baghdad",
    "merchant.sub": "List your venue on Wensa and take bookings straight from the app — no phone calls, no paper book.",
    "merchant.ctaPricing": "See pricing",
    "offer.badge": "Offer",
    "offer.title": "First month Pro free + 0% commission",
    "offer.body": "Your first month is on the full Pro plan, and we take zero commission on it.",
    "offer.fine": "After the first month, Pro is 60,000 IQD per month and standard commission applies.",
    "offer.free": "And the Basic plan stays free forever — nobody is forced onto a paid plan.",
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
    "what.title": "What can you do on Wensa?",
    "what.c1.title": "Discover",
    "what.c1.body": "Every good spot in Baghdad in one place — photos, hours, ratings and location.",
    "what.c2.title": "Book in a second",
    "what.c2.body": "A table, a court, a chalet or a concert ticket — book from your seat and pay in IQD.",
    "what.c3.title": "Your QR ticket",
    "what.c3.body": "Your ticket lives in the app. Show it at the door — no paper, no hassle.",
    "how.title": "How it works",
    "how.s1.title": "Get the app",
    "how.s1.body": "Free on iOS and Android.",
    "how.s2.title": "Pick your spot",
    "how.s2.body": "Browse by category, area or rating.",
    "how.s3.title": "Book and go",
    "how.s3.body": "Pay in IQD and get your QR ticket.",
    "trust.iqd": "Pay in IQD",
    "trust.qr": "QR ticket",
    "trust.cancel": "Easy cancellation",
    "num.1": "1",
    "num.2": "2",
    "num.3": "3",
    "dl.title": "Get Wensa and go",
    "dl.body": "Free, in Arabic, and built for Iraq. Download it and see what's on tonight.",
    "dl.qr": "Scan with your camera",
    "band.title": "Own a restaurant or a court?",
    "band.body": "Your first month is on us — Pro free and 0% commission.",
    "band.cta": "Become a merchant",
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
