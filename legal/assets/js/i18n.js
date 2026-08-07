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
    "meta.home.title": "ونسة: كل ونستك بمكان واحد",
    "meta.home.desc": "ونسة: كل ونستك بمكان واحد. مطاعم، ملاعب، مزارع وحفلات: شوف، احجز، وادفع بالبطاقة.",
    "meta.merchants.title": "صير تاجر بونسة",
    "meta.merchants.desc": "صير تاجر بونسة: اول شهر برو مجاناً و٠٪ عمولة. خلي مكانك يوصل لكل بغداد.",
    "meta.ogLocale": "ar_IQ",
    "merchant.ctaRegister": "سجّل هسه",
    "merchant.eyebrow": "لأصحاب الاماكن",
    "merchant.title": "خلي مكانك يوصل لكل بغداد",
    "merchant.sub": "اضم مكانك لونسة واستقبل حجوزات من التطبيق، بدون تلفونات وبدون دفتر حجوزات.",
    "merchant.ctaPricing": "شوف الاسعار",
    "offer.badge": "عرض",
    "offer.title": "اول شهر برو مجاناً + ٠٪ عمولة",
    "offer.body": "اول شهر الك على خطة برو كاملة، وماناخذ ولا فلس عمولة بيه.",
    "offer.fine": "بعد الشهر الاول، برو ٦٠٬٠٠٠ د.ع بالشهر وتنطبق العمولة الاعتيادية.",
    "offer.free": "وتبقى خطة اساسي مجانية دائماً، ماكو احد مجبور يدفع.",
    "ben.title": "شنو تاخذ لما تنضم؟",
    "ben.b1.title": "توصل لزباين جداد",
    "ben.b1.body": "مكانك يظهر لكل مستخدمي ونسة بالعراق.",
    "ben.b2.title": "حجوزات ٢٤ ساعة",
    "ben.b2.body": "الزبون يحجز حتى وانت نايم، بدون تلفون.",
    "ben.b3.title": "لوحة تحكم شاملة",
    "ben.b3.body": "تحكم بأوقات الاوقات الدوام، دير الخصومات، وشوف كل معاملات اماكنك من لوحة وحدة.",
    "ben.b4.title": "دخول بالـ QR",
    "ben.b4.body": "الزبون يوري تذكرته عالباب وتتأكد بثانية.",
    "ben.b5.title": "احصائيات حقيقية",
    "ben.b5.body": "شوف شكد واحد شاف مكانك وشكد حجز.",
    "ben.b6.title": "اعلانات وترويج",
    "ben.b6.body": "اعلانات داخل التطبيق وظهور بالصفحة الرئيسية.",
    "join.title": "شلون تنضم؟",
    "join.s1.title": "سجّل حسابك",
    "join.s1.body": "اسم، ايميل ورقم تلفون، بدقيقة.",
    "join.s2.title": "ضيف مكانك",
    "join.s2.body": "صور، اوقات الاوقات الدوام وموقع على الخريطة.",
    "join.s3.title": "نراجع ونوثق",
    "join.s3.body": "فريقنا يتأكد من المعلومات ويوثق مكانك.",
    "join.s4.title": "افتح واستقبل حجوزات",
    "join.s4.body": "مكانك يظهر بالتطبيق وتبدي تستقبل حجوزات.",
    "pricing.title": "الاسعار",
    "pricing.sub": "ابدا مجاناً وارتقي وقت ما تحتاج.",
    "plan.basic.name": "أساسي",
    "plan.basic.price": "مجاني",
    "plan.basic.f": "٢ أماكن + فعاليات مجمعة · ٣ صور إضافية · قائمة أساسية · ٥٬٠٠٠ د.ع لكل إعلان",
    "plan.growth.name": "نمو",
    "plan.growth.price": "٢٥٬٠٠٠ د.ع / شهر",
    "plan.growth.badge": "الأكثر شيوعاً",
    "plan.growth.f": "١٠ أماكن + فعاليات مجمعة · صور غير محدودة · زر التواصل المباشر · إحصائيات أساسية · ٣ إعلانات مجانية/شهر + ٥٬٠٠٠ د.ع بعدها",
    "plan.pro.name": "احترافي",
    "plan.pro.price": "٦٠٬٠٠٠ د.ع / شهر",
    "plan.pro.note": "اول شهر مجاناً",
    "plan.pro.f": "أماكن + فعاليات غير محدودة · إحصائيات متقدمة · أولوية الظهور · شارة التحقق · ترويج رئيسية · موظفون متعددون · ١٠ إعلانات مجانية/شهر + ٥٬٠٠٠ د.ع بعدها",
    "faq.title": "اسئلة شائعة",
    "faq.q1": "شكد العمولة؟",
    "faq.a1": "العمولة ١٣٪.",
    "faq.q2": "امتى توصلني فلوسي؟",
    "faq.a2": "التحويل مجاني بدون عمولة، اسبوعي او شهري حسب الاتفاق.",
    "faq.q3": "اكو عقد لازم اوقعه؟",
    "faq.a3": "لا، ماكو عقد لازم توقعه، تكدر تبدي مباشرة.",
    "faq.q4": "عندي كم مكان، كلهم بحساب واحد؟",
    "faq.a4": "اي، تكدر تدير اكثر من مكان بنفس الحساب.",
    "close.title": "يلا نبدي",
    "close.body": "سجّل مكانك بدقايق واستقبل اول حجز.",
    "hero.eyebrow": "نزل هسه، مجاناً",
    "hero.lead": "احجز",
    "hero.trail": "بثانية وحدة",
    "hero.sub": "كل الأماكن اللي تحبها بمكان واحد. دور، احجز، وادفع بكل سهولة.",
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
    "what.c1.body": "استكشف أفضل المطاعم، الملاعب، المزارع والفعاليات، وكل التفاصيل اللي تساعدك تختار المكان المناسب.",
    "what.c2.title": "احجز بثانية",
    "what.c2.body": "اختار المكان والوقت المناسب إلك، واحجز بخطوات بسيطة.",
    "what.c3.title": "تذكرتك QR",
    "what.c3.body": "بعد الحجز، تذكرتك توصلك مباشرة، وكل اللي عليك تمسح رمز الـ QR عند الدخول.",
    "how.title": "شلون تشتغل؟",
    "how.s1.title": "نزّل التطبيق",
    "how.s1.body": "متوفر مجاناً على iPhone وAndroid.",
    "how.s2.title": "اختار مكانك",
    "how.s2.body": "دور حسب النوع، المنطقة أو الوقت اللي يناسبك.",
    "how.s3.title": "احجز وروح",
    "how.s3.body": "ادفع بالبطاقة، واستلم تذكرتك مباشرة.",
    "trust.iqd": "دفعبالبطاقة",
    "trust.qr": "تذكرة QR",
    "trust.cancel": "إلغاء سهل",
    "num.1": "١",
    "num.2": "٢",
    "num.3": "٣",
    "num.4": "٤",
    "dl.title": "نزّل ونسة هسه",
    "dl.body": "حمّل التطبيق وخلي كل طلعاتك وحجوزاتك بمكان واحد.",
    "dl.qr": "صوّر الكود بكاميرتك",
    "band.title": "عندك مشروع؟",
    "band.body": "عندك مزرعة، ملعب أو أي مكان ترفيهي؟ انضم ويانه وخلي الناس توصل إلك بسهولة من خلال ونسة. أول شهر برو علينا، وبدون أي عمولة.",
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
    "meta.home.title": "Wensa: Everything you do, in one place",
    "meta.home.desc": "Wensa: everything you do, in one place. Restaurants, courts, farms and concerts: browse, book, and pay in IQD.",
    "meta.merchants.title": "Become a Wensa merchant",
    "meta.merchants.desc": "Become a Wensa merchant: first month Pro free and 0% commission. Put your venue in front of all Baghdad.",
    "meta.ogLocale": "en_US",
    "merchant.ctaRegister": "Register now",
    "merchant.eyebrow": "For venue owners",
    "merchant.title": "Put your venue in front of all Baghdad",
    "merchant.sub": "List your venue on Wensa and take bookings straight from the app, with no phone calls and no paper book.",
    "merchant.ctaPricing": "See pricing",
    "offer.badge": "Offer",
    "offer.title": "First month Pro free + 0% commission",
    "offer.body": "Your first month is on the full Pro plan, and we take zero commission on it.",
    "offer.fine": "After the first month, Pro is 60,000 IQD per month and standard commission applies.",
    "offer.free": "And the Basic plan stays free forever: nobody is forced onto a paid plan.",
    "ben.title": "What you get",
    "ben.b1.title": "Reach new customers",
    "ben.b1.body": "Your venue appears to every Wensa user in Iraq.",
    "ben.b2.title": "Bookings around the clock",
    "ben.b2.body": "Customers book even while you sleep, no phone calls.",
    "ben.b3.title": "Full dashboard control",
    "ben.b3.body": "Set your opening hours, manage discounts, and see every transaction across all your venues from one dashboard.",
    "ben.b4.title": "QR check in",
    "ben.b4.body": "Guests show their ticket at the door and you verify in a second.",
    "ben.b5.title": "Real analytics",
    "ben.b5.body": "See how many people viewed your venue and how many booked.",
    "ben.b6.title": "Banners and promotion",
    "ben.b6.body": "In app banners and home feed placement.",
    "join.title": "How to join",
    "join.s1.title": "Create your account",
    "join.s1.body": "Name, email and phone. Takes a minute.",
    "join.s2.title": "Add your venue",
    "join.s2.body": "Photos, opening hours and a map location.",
    "join.s3.title": "We review and verify",
    "join.s3.body": "Our team checks the details and verifies your venue.",
    "join.s4.title": "Go live and take bookings",
    "join.s4.body": "Your venue appears in the app and bookings start coming in.",
    "pricing.title": "Pricing",
    "pricing.sub": "Start free and upgrade whenever you need to.",
    "plan.basic.name": "Basic",
    "plan.basic.price": "Free",
    "plan.basic.f": "2 combined places & events · 3 additional photos · Basic listing · 5,000 IQD for each banner",
    "plan.growth.name": "Growth",
    "plan.growth.price": "25,000 IQD / month",
    "plan.growth.badge": "Most Popular",
    "plan.growth.f": "10 combined places & events · Unlimited photos · Direct contact button · Basic analytics · 3 free banners/month + 5,000 IQD each after",
    "plan.pro.name": "Pro",
    "plan.pro.price": "60,000 IQD / month",
    "plan.pro.note": "First month free",
    "plan.pro.f": "Unlimited places & events · Advanced analytics · Priority placement · Verified badge · Home feed promotion · Multi staff access · 10 free banners/month + 5,000 IQD each after",
    "faq.title": "Frequently asked",
    "faq.q1": "What's the commission?",
    "faq.a1": "Commission is 13%.",
    "faq.q2": "When do I get paid?",
    "faq.a2": "Transfers are free, no commission, weekly or monthly depending on your agreement.",
    "faq.q3": "Do I need to sign a contract?",
    "faq.a3": "No, there is no contract to sign. You can start right away.",
    "faq.q4": "I have several venues, one account?",
    "faq.a4": "Yes, you can manage more than one venue from the same account.",
    "close.title": "Let's get started",
    "close.body": "Register your venue in minutes and take your first booking.",
    "hero.eyebrow": "Out now, free",
    "hero.lead": "Book",
    "hero.trail": "in one second",
    "hero.sub": "All the places you love, in one place. Browse, book, and pay with ease.",
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
    "what.c1.body": "Explore the best restaurants, courts, farms, and events, with all the details that help you pick the right place.",
    "what.c2.title": "Book in a second",
    "what.c2.body": "Choose the place and time that suit you, and book in a few simple steps.",
    "what.c3.title": "Your QR ticket",
    "what.c3.body": "After booking, your ticket arrives right away, just scan the QR code at the entrance.",
    "how.title": "How it works",
    "how.s1.title": "Get the app",
    "how.s1.body": "Available for free on iPhone and Android.",
    "how.s2.title": "Pick your spot",
    "how.s2.body": "Search by category, area, or the time that works for you.",
    "how.s3.title": "Book and go",
    "how.s3.body": "Pay by card, and get your ticket instantly.",
    "trust.iqd": "Pay in IQD",
    "trust.qr": "QR ticket",
    "trust.cancel": "Easy cancellation",
    "num.1": "1",
    "num.2": "2",
    "num.3": "3",
    "num.4": "4",
    "dl.title": "Download Wensa now",
    "dl.body": "Get the app and keep all your outings and bookings in one place.",
    "dl.qr": "Scan with your camera",
    "band.title": "Got a business?",
    "band.body": "Have a farm, a court, or any entertainment venue? Join Wensa and let people find you easily. Your first month on Pro is on us, with zero commission.",
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

  // The toggle's own label is written in the OPPOSITE language on purpose
  // ("English" while the page is Arabic, and vice versa), so it needs its own
  // lang attribute or a screen reader applies the page's voice/pronunciation
  // rules to text in the other script.
  for (const btn of document.querySelectorAll("[data-lang-toggle]")) {
    btn.lang = safe === "ar" ? "en" : "ar";
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
