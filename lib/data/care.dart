class CheckItem {
  const CheckItem({required this.id, required this.section, required this.label});

  final String id;
  final String section;
  final String label;
}

const hospitalBag = <CheckItem>[
  CheckItem(id: 'id', section: 'أوراق', label: 'البطاقة أو إثبات الشخصية'),
  CheckItem(id: 'reports', section: 'أوراق', label: 'تقارير المتابعة وأشعة السونار'),
  CheckItem(id: 'insurance', section: 'أوراق', label: 'أوراق التأمين أو عنوان المستشفى والاتفاق'),
  CheckItem(id: 'cash', section: 'أوراق', label: 'فلوس بسيطة أو كارت'),
  CheckItem(id: 'gown', section: 'للأم', label: 'قميص مريح للولادة وبعدها'),
  CheckItem(id: 'clothes', section: 'للأم', label: 'لبس خروج واسع وشرّابة'),
  CheckItem(id: 'pads', section: 'للأم', label: 'فوط الولادة اللي المستشفى طلبتها'),
  CheckItem(id: 'wash', section: 'للأم', label: 'أدوات استحمام وربطة شعر'),
  CheckItem(id: 'charger', section: 'للأم', label: 'شاحن طويل وسماعات'),
  CheckItem(id: 'snacks', section: 'للأم', label: 'سناك خفيف لو الطبيب سامح بعد الولادة'),
  CheckItem(id: 'outfit', section: 'للبيبي', label: 'طقم خروج واتنين بودي'),
  CheckItem(id: 'blanket', section: 'للبيبي', label: 'بطانية خفيفة وقبعة'),
  CheckItem(id: 'diapers', section: 'للبيبي', label: 'حفاضات مقاس مولود'),
  CheckItem(id: 'wipes', section: 'للبيبي', label: 'مناديل مبللة'),
];

class VaccineDose {
  const VaccineDose({
    required this.id,
    required this.title,
    required this.detail,
    required this.day,
  });

  final String id;
  final String title;
  final String detail;
  final int day;
}

const egyptVaccines = <VaccineDose>[
  VaccineDose(
    id: 'birth',
    title: 'عند الولادة',
    detail: 'الالتهاب الكبدي B خلال أول ٢٤ ساعة، وشلل الأطفال الفموي (سابين)، والدرن BCG.',
    day: 0,
  ),
  VaccineDose(
    id: 'm2',
    title: 'عمر شهرين',
    detail: 'سابين، والتطعيم الخماسي، وشلل الأطفال بالحقن (سولك). تأكدي من الوحدة لأن الجرعات اتوسعت.',
    day: 60,
  ),
  VaccineDose(
    id: 'm4',
    title: 'عمر ٤ شهور',
    detail: 'سابين، والخماسي، وسولك.',
    day: 122,
  ),
  VaccineDose(
    id: 'm6',
    title: 'عمر ٦ شهور',
    detail: 'سابين، والخماسي، وسولك.',
    day: 183,
  ),
  VaccineDose(
    id: 'm9',
    title: 'عمر ٩ شهور',
    detail: 'سابين، وفيتامين A حسب جدول الوحدة الصحية.',
    day: 274,
  ),
  VaccineDose(
    id: 'm12',
    title: 'عمر ١٢ شهر',
    detail: 'سابين، والحصبة والنكاف والحصبة الألماني MMR.',
    day: 365,
  ),
  VaccineDose(
    id: 'm18',
    title: 'عمر ١٨ شهر',
    detail: 'منشّط سابين، والثلاثي البكتيري، ومنشّط MMR، وفيتامين A.',
    day: 548,
  ),
];

const vaccineDisclaimer =
    'الجدول متبني على التطعيم الروتيني اللي بتنشره وزارة الصحة المصرية، وممكن يتحدث. الوحدة الصحية أو طبيب الأطفال هما المعاد الرسمي، والتطبيق تذكير بس.';

class CareCard {
  const CareCard({required this.title, required this.body});

  final String title;
  final String body;
}

List<CareCard> recoveryCards({required int days, required bool cesarean}) {
  final cards = <CareCard>[
    if (days < 0)
      const CareCard(
        title: 'لسه قبل تاريخ الولادة',
        body: 'لو التاريخ اتسجل بالغلط، عدّليه من الإعدادات. النصايح دي بعد الولادة.',
      )
    else if (days <= 10)
      const CareCard(
        title: 'أول أيام النفاس',
        body: 'النزيف بعد الولادة بيبقى أقوى من الدورة عند ناس كتير وبيخف بالتدريج. لو الفوطة بتتملي بسرعة، أو فيه دوخة، أو ريحته غريبة مع سخونية، كلّمي الطبيب أو ارجعي للمستشفى.',
      )
    else if (days <= 40)
      const CareCard(
        title: 'الأربعين',
        body: 'النوم متقطع والهرمونات لسه بتترتب. المساعدة في الأكل والبيت مش رفاهية. الحزن الخفيف شائع، ولو الحزن تقيل أو فيه أفكار تخوفكِ كلّمي طبيبك وحد قريب النهاردة.',
      )
    else
      const CareCard(
        title: 'بعد الأربعين',
        body: 'متابعة ما بعد الولادة لسه مهمة حتى لو الجرح شكله كويس. منع الحمل والرضاعة والحركة بيرجعوا لخطة الطبيب، مش لمنشور واحد.',
      ),
    if (cesarean)
      const CareCard(
        title: 'الجرح القيصرية',
        body: 'ما تشيليش حاجة تقيلة، واتبعي تعليمات الغيار. احمرار بينتشر، أو سخونية، أو إفراز من الجرح، أو ألم بيزيد بدل ما يخف: اتصال بالطبيب.',
      )
    else if (days >= 0)
      const CareCard(
        title: 'بعد الولادة الطبيعية',
        body: 'الحرقان أو الخياطة لو موجودة بيتظبطوا بالنضافة والتعليمات اللي خرجتي بيها. الألم اللي بيزيد أو الحرقة مع بول دم يستاهل سؤال الطبيب.',
      ),
    const CareCard(
      title: 'الرضاعة',
      body: 'الوضعية المريحة وتبديل الناحية بيساعدوا. الألم الشديد في الحلمة أو جزء صلب سخن في الثدي ممكن يبقى احتقان أو التهاب. استشاري الرضاعة أو الطبيب أفيد من الاستسلام للألم.',
    ),
  ];
  return cards;
}

const soothingIdeas = <CareCard>[
  CareCard(
    title: 'قبل ما نخمّن السبب',
    body: 'الجوع، الحفاض، الحر، والتعب أكتر أسباب البكاء. لو البكاء مختلف أو معه سخونية أو خمول أو رفض رضاعة، الطبيب مش قائمة التطبيق.',
  ),
  CareCard(
    title: 'التهدئة الهادية',
    body: 'حضن ملاصق، ربّاتة متكررة، إضاءة أهدى، وصوت ثابت زي مروحة أو مطر من موبايلك. جربي حاجة واحدة كام دقيقة قبل ما تبدلي عشرة طرق.',
  ),
  CareCard(
    title: 'إنتِ كمان',
    body: 'لو البكاء طول وأنتِ لوحدك، حطي البيبي في مكان آمن وابعدي لدقيقة وتصلي بحد. طلب المساعدة مش فشل.',
  ),
];

const ttcPrep = <CareCard>[
  CareCard(
    title: 'حمض الفوليك',
    body: 'الأطباء عادةً بينصحوا بيه قبل الحمل بفترة. الجرعة مش موحدة لكل الناس، خصوصًا لو فيه تاريخ مرضي. اسألي قبل ما تنسخي علبة حد تاني.',
  ),
  CareCard(
    title: 'الدورة مش ساعة',
    body: 'نافذة الخصوبة في هي تقدير من طول دورتك. تحليل التبويض أو متابعة الطبيب أدق لو المحاولة طوّلت أو الدورة مش منتظمة.',
  ),
  CareCard(
    title: 'اللي بيتوقف قبل الحمل',
    body: 'علاجات البشرة اللي فيها ريتينويد، وبعض الأدوية المزمنة، بتتراجع مع الطبيب قبل المحاولة. الإيقاف المفاجئ من غير طبيب مش خطة.',
  ),
  CareCard(
    title: 'اليوم العادي',
    body: 'نوم يكفيكِ، وتقليل الطاقة والمشروبات، وحركة تحبيها. مفيش أكلة بتحبس الحمل، ومفيش أكلة بتضمنه.',
  ),
];

const prepSymptoms = ['إفرازات شفافة', 'مغص خفيف', 'طاقة', 'توتر', 'نفخ', 'نوم تقيل'];

class FeelNote {
  const FeelNote(this.label, this.meaning);

  final String label;
  final String meaning;
}

const pregnantSymptoms = <FeelNote>[
  FeelNote('غثيان', 'شائع خصوصًا في الشهور الأولى. لو مش قادرة تشربي خالص، أو الوزن بينزل بسرعة، قولي للطبيب.'),
  FeelNote('إرهاق', 'جسمك شغال زيادة. غفوة قصيرة عادية. لو الإرهاق مع دوخة شديدة أو نزيف، اتصلي.'),
  FeelNote('حموضة', 'المعدة بتتضايق من الهرمونات، وبعدين من حجم الرحم. وجبات أصغر أحيانًا بتريح. الألم الجديد والشديد للطبيب.'),
  FeelNote('صداع خفيف', 'وارد مع التعب وقلة النوم. الصداع الشديد، أو اللي مع زغللة، اتصال بالطبيب مش مسكن من غير ما يسأل.'),
  FeelNote('طاقة', 'يوم أخف. استغليه في حاجة خفيفة تحبيها، من غير ما تعوضي الأيام التقيلة كلها.'),
  FeelNote('قلق', 'وارد تحسي بيه. لو مش سايبك تنامي أو تاكلي، احكي لحد تثقي فيه أو للطبيب.'),
  FeelNote('أرق', 'النوم بيتقطع عند ناس كتير. غفوة بالنهار مش غلط. ضيق النفس وأنتِ قاعدة محتاج اتصال.'),
  FeelNote('شد خفيف', 'شد بيروح مع الراحة شائع. الشد المنتظم والقريب من بعضه، أو اللي مع نزيف، للطبيب مش للعدّاد.'),
];

const postpartumMoods = ['هادية', 'تعبانة', 'حزينة شوية', 'متوترة', 'مبسوطة'];

const pregnantMoods = <FeelNote>[
  FeelNote('هادية', 'اليوم هادي، واتسجل كده. مش لازم إحساس أقوى عشان اليوم يبقى تمام.'),
  FeelNote('تعبانة', 'اتسجل إنك تعبانة. راحة قصيرة، من غير ما تبرري لحد.'),
  FeelNote('متوترة', 'اتسجل التوتر. لو قاعد معاكِ أيام ومش سايبك تنامي، احكي للي جنبك أو للطبيب.'),
  FeelNote('مبسوطة', 'اتسجل اليوم ده. يستاهل يتفتكر زي ما هو.'),
  FeelNote('حساسة', 'اتسجل. الحساسية دي هرمونات يوم، مش إنك ضعيفة.'),
];

const ttcMoods = ['متفائلة', 'هادية', 'قلقانة', 'تعبانة', 'مبسوطة'];

String? feelMeaning(List<FeelNote> notes, String? label) {
  if (label == null) return null;
  for (final note in notes) {
    if (note.label == label) return note.meaning;
  }
  return null;
}
