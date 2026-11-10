enum SafetyLevel { green, amber, red }

enum GuideKind { medicine, food, herb, vitamin }

class GuideItem {
  const GuideItem({
    required this.name,
    required this.kind,
    required this.level,
    required this.note,
    required this.aliases,
  });

  final String name;
  final GuideKind kind;
  final SafetyLevel level;
  final String note;
  final List<String> aliases;
}

const safetyDisclaimer =
    'الدليل ده للمعرفة العامة فقط. مش روشتة، ومش بيستبدل الطبيب أو الصيدلي. الجرعة والتوقيت بيتحددوا على حالتكِ أنتِ.';

const guideItems = <GuideItem>[
  GuideItem(
    name: 'حمض الفوليك',
    kind: GuideKind.vitamin,
    level: SafetyLevel.green,
    note: 'من المكملات اللي الخطط الطبية عادةً بتنصح بيها قبل الحمل وفي أوله. الجرعة والمدة يكتبهم الطبيب، ومش كل الناس نفس الرقم.',
    aliases: ['فوليك', 'folic', 'folic acid'],
  ),
  GuideItem(
    name: 'فيتامينات ما قبل الولادة الموصوفة',
    kind: GuideKind.vitamin,
    level: SafetyLevel.green,
    note: 'لما الطبيب يختارها، بتبقى جزء من المتابعة. منتج صاحبتِك مش بالضرورة مناسب ليكي.',
    aliases: ['prenatal', 'فيتامين حمل'],
  ),
  GuideItem(
    name: 'أكل مطبوخ ومتغسل كويس',
    kind: GuideKind.food,
    level: SafetyLevel.green,
    note: 'الخضار والفاكهة بعد الغسل، والبيض واللحم بعد الاستواء، واللبن المبستر: أساس أهدى من قوائم المنع العشوائية.',
    aliases: ['خضار', 'فاكهة', 'أكل بيتي', 'vegetable', 'vegetables'],
  ),
  GuideItem(
    name: 'فاكهة مغسولة',
    kind: GuideKind.food,
    level: SafetyLevel.green,
    note: 'الفاكهة بعد الغسل أكل عادي في الحمل. المانجا مش بتعمل تشوهات. لو عندكِ سكري حمل، الكمية تتظبط مع الطبيب.',
    aliases: ['مانجا', 'مانجو', 'mango', 'تفاح', 'apple', 'موز', 'banana', 'فراولة', 'strawberry', 'عنب', 'grape', 'grapes', 'fruit'],
  ),
  GuideItem(
    name: 'الجبنة واللبن',
    kind: GuideKind.food,
    level: SafetyLevel.amber,
    note: 'المبستر غالبًا مناسب. الجبنة أو اللبن غير المبستر بيتجنب. لو مش مكتوب على العلبة إنه مبستر، اسألي قبل ما تأكلي.',
    aliases: ['جبنة', 'جبن', 'cheese', 'زبادي', 'yogurt'],
  ),
  GuideItem(
    name: 'البيض',
    kind: GuideKind.food,
    level: SafetyLevel.amber,
    note: 'البيض كامل الاستواء مناسب. النيء والبرشت بيتجنبوا عشان احتمال العدوى.',
    aliases: ['بيض', 'egg', 'eggs'],
  ),
  GuideItem(
    name: 'المية والسوائل',
    kind: GuideKind.food,
    level: SafetyLevel.green,
    note: 'السوائل بتفرق في الإمساك والإحساس بالدوخة. الكمية تتظبط مع الطبيب لو فيه تقيؤ أو مشكلة كلى.',
    aliases: ['ماء', 'مية', 'سوائل'],
  ),
  GuideItem(
    name: 'الباراسيتامول',
    kind: GuideKind.medicine,
    level: SafetyLevel.amber,
    note: 'مسكن بيتستخدم أحيانًا في الحمل للحرارة أو الألم، بس الجرعة وعدد المرات قرار الطبيب أو الصيدلي. مش لأنه "أخضر" يبقى مفتوح من غير حد.',
    aliases: ['بنادول', 'باراسيتامول', 'paracetamol', 'panadol', 'adol', 'ادول', 'acetaminophen'],
  ),
  GuideItem(
    name: 'الحديد',
    kind: GuideKind.vitamin,
    level: SafetyLevel.amber,
    note: 'بيتطلب لما التحليل أو الطبيب يحتاجه. أحيانًا بيتاخد بعيد عن الكالسيوم عشان الامتصاص. الترتيب يتكتب في الروشتة.',
    aliases: ['حديد', 'iron'],
  ),
  GuideItem(
    name: 'الكالسيوم',
    kind: GuideKind.vitamin,
    level: SafetyLevel.amber,
    note: 'مهم في الغذا لو الطبيب شايف كده. ما تزوديش مكمل من نفسك عشان "البيبي بياخد من ضروسي".',
    aliases: ['كالسيوم', 'calcium'],
  ),
  GuideItem(
    name: 'أوميجا 3',
    kind: GuideKind.vitamin,
    level: SafetyLevel.amber,
    note: 'بعض الأطباء بيضيفوه من مصدر موثوق. زيت كبد الحوت العالي في فيتامين A مش نفس الحاجة، وده بيتراجع مع الطبيب.',
    aliases: ['اوميجا', 'omega'],
  ),
  GuideItem(
    name: 'الكافيين',
    kind: GuideKind.food,
    level: SafetyLevel.amber,
    note: 'جهات كتير بتنصح بتقليل القهوة والشاي والمشروبات الطاقة في الحمل. الحد المناسب لحالتكِ يتقال في العيادة، ومش من منشور.',
    aliases: ['قهوة', 'شاي', 'كافيين', 'نسكافيه', 'coffee', 'espresso'],
  ),
  GuideItem(
    name: 'سمك قليل الزئبق مطبوخ',
    kind: GuideKind.food,
    level: SafetyLevel.amber,
    note: 'أنواع زي البلطي والسلمون المطبوخين غالبًا بيتسمح بيهم باعتدال. النيء والمدخن والمقلي الوسخ قصة تانية.',
    aliases: ['سمك', 'سلمون', 'بلطي', 'salmon', 'tilapia', 'fish'],
  ),
  GuideItem(
    name: 'الإيبوبروفين ومضادات الالتهاب',
    kind: GuideKind.medicine,
    level: SafetyLevel.red,
    note: 'بتتجنب في الحمل إلا لو طبيب متخصص طلبها لحالة معينة. الخطر أوضح في الشهور الأخيرة. البروفين والبروفين البارد مش اختيار من الدرج.',
    aliases: ['بروفين', 'ايبوبروفين', 'ibuprofen', 'كتافلام', 'ديكلوفيناك', 'brufen', 'advil', 'nurofen', 'profen'],
  ),
  GuideItem(
    name: 'الإيزوتريتينوين ومشتقات فيتامين A العلاجية',
    kind: GuideKind.medicine,
    level: SafetyLevel.red,
    note: 'رواكوتان وأشباهه، والريتينول العلاجي والتريتينوين للبشرة، من أشهر المواد المرتبطة بتشوهات الجنين. أي علاج بشرة قديم يتراجع قبل الحمل ومع الطبيب.',
    aliases: ['رواكوتان', 'روأكيوتان', 'retinoid', 'retinol', 'isotretinoin', 'تريتينوين', 'roaccutane', 'accutane'],
  ),
  GuideItem(
    name: 'الكحول',
    kind: GuideKind.food,
    level: SafetyLevel.red,
    note: 'مفيش كمية متفق عليها إنها آمنة في الحمل. ده يشمل النبيذ "الخفيف" والحلويات اللي فيها كحول نيء.',
    aliases: ['خمرة', 'كحول', 'بيرة', 'نبيذ', 'wine', 'beer', 'alcohol', 'vodka', 'whiskey', 'cocktail'],
  ),
  GuideItem(
    name: 'اللحوم والبيض النيء',
    kind: GuideKind.food,
    level: SafetyLevel.red,
    note: 'البيض البرشت واللحم الورد والمايونيز النيء بيعرضوا لعدوى ممكن تأذي الحمل. الاستواء الكامل أأمن.',
    aliases: ['بيض نيء', 'ستيك نيء', 'برشت', 'مايونيز نيء', 'سوشي', 'sushi', 'sashimi'],
  ),
  GuideItem(
    name: 'الألبان والأجبان غير المبسترة',
    kind: GuideKind.food,
    level: SafetyLevel.red,
    note: 'الجبنة الطرية من لبن نيء ممكن تحمل ليستريا. اختاري المبستر، ولو مش متأكدة اسألي.',
    aliases: ['جبنة نيء', 'لبن غير مبستر', 'قشطة بلدي'],
  ),
  GuideItem(
    name: 'السمك العالي الزئبق',
    kind: GuideKind.food,
    level: SafetyLevel.red,
    note: 'القرش وسمك السيف والماكريل الملكي من الأنواع اللي بتتجنب بسبب الزئبق. النوع المحلي لو مش معروف، اسألي قبل ما يتكرر كل أسبوع.',
    aliases: ['قرش', 'زئبق', 'shark', 'swordfish'],
  ),
  GuideItem(
    name: 'السجائر والشيشة',
    kind: GuideKind.medicine,
    level: SafetyLevel.red,
    note: 'التدخين والشيشة والفيب بيرفعوا مخاطر كتير على الحمل والبيبي. المساعدة في الإقلاع موجودة عند الطبيب، ومش لازم تستني "بعد الولادة".',
    aliases: ['سجائر', 'شيشة', 'فيب', 'دخان', 'cigarette', 'tobacco', 'smoking'],
  ),
  GuideItem(
    name: 'أعشاب مركزة ومشروبات تخسيس',
    kind: GuideKind.herb,
    level: SafetyLevel.red,
    note: 'الميرمية والقرفة والحلبة بكميات علاجية، والجنسنج، وخلطات الدورة أو الرحم، مش آمنة لمجرد إنها طبيعية. كوب شاي خفيف برضو يتسأل عنه لو بيتشرب يوميًا.',
    aliases: ['مرمية', 'قرفة', 'حلبة', 'جنسنج', 'أعشاب', 'تخسيس'],
  ),
  GuideItem(
    name: 'أدوية قديمة من غير مراجعة',
    kind: GuideKind.medicine,
    level: SafetyLevel.red,
    note: 'دواء الضغط أو الصرع أو الحب الشباب أو حتى حساسية كنتِ بتاخديه قبل الحمل ما يتوقفش وما يتكمّلش من غير الطبيب. الإيقاف المفاجئ أحيانًا خطر هو كمان.',
    aliases: ['روشتة قديمة', 'دواء قديم'],
  ),
];

String kindLabel(GuideKind kind) {
  return switch (kind) {
    GuideKind.medicine => 'دواء',
    GuideKind.food => 'أكل',
    GuideKind.herb => 'عشب',
    GuideKind.vitamin => 'فيتامين',
  };
}

String levelLabel(SafetyLevel level) {
  return switch (level) {
    SafetyLevel.green => 'غالبًا مناسب بمتابعة',
    SafetyLevel.amber => 'بحذر وبقرار طبي',
    SafetyLevel.red => 'بيتجنب إلا بقرار متخصص',
  };
}

class ReportTerm {
  const ReportTerm({
    required this.code,
    required this.title,
    required this.plain,
  });

  final String code;
  final String title;
  final String plain;
}

const reportTerms = <ReportTerm>[
  ReportTerm(
    code: 'CRL',
    title: 'طول التاج المقعد',
    plain: 'طول الجنين من رأسه لأسفل ظهره في أول الحمل. الطبيب بيستخدمه عشان يقدّر العمر. الرقم لوحده من غير سياق الفحص مش خبر سعيد ولا مخيف.',
  ),
  ReportTerm(
    code: 'BPD',
    title: 'قطر الرأس',
    plain: 'قياس عرض رأس الجنين. بيتقارن بعمر الحمل عند الطبيب، ومش بيتقرأ كحكم نهائي من ورقة واحدة.',
  ),
  ReportTerm(
    code: 'HC',
    title: 'محيط الرأس',
    plain: 'مقياس حوالين الرأس. بيكمل صورة النمو مع باقي المقاسات، ومش بيشرح لوحده.',
  ),
  ReportTerm(
    code: 'AC',
    title: 'محيط البطن',
    plain: 'مقياس بطن الجنين، وبيساعد في تقدير النمو. أي كلمة "صغير" أو "كبير" محتاجة تفسير الطبيب مش ترجمة حرفية.',
  ),
  ReportTerm(
    code: 'FL',
    title: 'طول عظمة الفخذ',
    plain: 'طول فخذ الجنين. مقياس نمو شائع، وبيتقرأ مع باقي الجسم.',
  ),
  ReportTerm(
    code: 'EFW',
    title: 'الوزن التقديري',
    plain: 'تقدير لوزن الجنين محسوب من المقاسات، وفيه هامش خطأ طبيعي. مش ميزان حقيقي.',
  ),
  ReportTerm(
    code: 'FHR',
    title: 'نبض القلب',
    plain: 'عدد نبضات قلب الجنين في الدقيقة وقت الفحص. الطبيعي مدى واسع، والطبيب هو اللي يقول الرقم ده مناسب للحظة دي ولا لأ.',
  ),
  ReportTerm(
    code: 'AFI',
    title: 'مؤشر السائل',
    plain: 'تقدير لكمية السائل حوالين الجنين. الزيادة أو النقص ليهم أسباب مختلفة، والمتابعة طبية.',
  ),
  ReportTerm(
    code: 'MVP',
    title: 'أعمق جيب للسائل',
    plain: 'طريقة تانية يقيسوا بيها السائل. الاسم التقني مش معناه إن فيه مشكلة.',
  ),
  ReportTerm(
    code: 'NT',
    title: 'الشفافية القفوية',
    plain: 'قياس في أول الحمل بيتاخد مع تحاليل تانية لتقييم احتمالات، ومش تشخيص لوحده.',
  ),
  ReportTerm(
    code: 'GA',
    title: 'عمر الحمل',
    plain: 'عمر الحمل بالأسابيع والأيام حسب آخر دورة أو السونار المبكر. الأسبوع المكتوب على الورقة هو مرجع التقرير.',
  ),
  ReportTerm(
    code: 'EDD',
    title: 'ميعاد الولادة المتوقع',
    plain: 'تاريخ تقريبي. أغلب الولادات بتحصل حوالينه، مش في اليوم بالدقيقة.',
  ),
  ReportTerm(
    code: 'LMP',
    title: 'آخر دورة',
    plain: 'أول يوم في آخر دورة شهرية. عليه بيتبني حساب كتير، ولو التاريخ مش متظبط الطبيب بيعدّل من السونار.',
  ),
  ReportTerm(
    code: 'cephalic',
    title: 'وضع رأسي',
    plain: 'رأس الجنين لتحت. وضع شائع قرب الولادة، وبرضو مش وعد بطريقة ولادة معينة.',
  ),
  ReportTerm(
    code: 'breech',
    title: 'وضع مقعدي',
    plain: 'مقعدة الجنين لتحت. في شهور كتير بيتغير الوضع لوحده. قرار الولادة بيتاخد مع الطبيب حسب الأسبوع والحالة.',
  ),
  ReportTerm(
    code: 'placenta previa',
    title: 'مشيمة متقدمة',
    plain: 'المشيمة نازلة قريبة من عنق الرحم أو مغطية عليه. دي متابعة طبية، ومش معلومة تتطمن عليها من تطبيق. التزمي بتعليمات طبيبك في الحركة والجماع والنزيف.',
  ),
  ReportTerm(
    code: 'anterior placenta',
    title: 'مشيمة أمامية',
    plain: 'المشيمة في الجدار الأمامي للرحم. أحيانًا بتأخر الإحساس بالحركة، وده شرح شائع عند الأطباء ومش حكم على الجنين.',
  ),
  ReportTerm(
    code: 'posterior placenta',
    title: 'مشيمة خلفية',
    plain: 'المشيمة في الجدار الخلفي. وصف للمكان، مش درجة خطورة.',
  ),
];

List<ReportTerm> termsInText(String text) {
  final normalized = text.toLowerCase();
  return reportTerms.where((term) => normalized.contains(term.code.toLowerCase())).toList();
}
