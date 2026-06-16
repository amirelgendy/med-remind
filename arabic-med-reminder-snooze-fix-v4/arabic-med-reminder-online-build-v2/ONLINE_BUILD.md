# Build APK Online

## أسهل اختيار: GitHub Actions

1. افتح GitHub من المتصفح واعمل repository جديد.
2. ارفع ملفات المشروع كما هي.
3. افتح تبويب Actions.
4. اختر Build Android APK.
5. اضغط Run workflow.
6. بعد انتهاء البناء، افتح آخر run وحمّل artifact باسم:
   `arabic-med-reminder-debug-apk`
7. فك الضغط، وانقل `app-debug.apk` للموبايل وثبته.

## اختيار بديل: Codemagic

1. افتح Codemagic.
2. اربط المشروع من GitHub.
3. اختر workflow باسم Android Debug APK.
4. شغل build.
5. حمّل `app-debug.apk` من Artifacts.

ملف APK debug مناسب للتثبيت المباشر على الموبايل للاستخدام الشخصي. للنشر على Google Play ستحتاج build release وتوقيع رسمي.
