
для сборки билда под МакОС выполнить инструкции:
Compiled (dynamic) library (macOS)
To add a closed source library to a Flutter macOS Desktop app, use the following instructions:

Follow the instructions for Flutter desktop to create a Flutter desktop app.
Open the yourapp/macos/Runner.xcworkspace in Xcode.
Drag your precompiled library (libyourlibrary.dylib) into Runner/Frameworks.
Click Runner and go to the Build Phases tab.
Drag libyourlibrary.dylib into the Copy Bundle Resources list.
Under Embed Libraries, check Code Sign on Copy.
Under Link Binary With Libraries, set status to Optional. (We use dynamic linking, no need to statically link.)
Click Runner and go to the General tab.
Drag libyourlibrary.dylib into the Frameworks, Libraries and Embedded Content list.
Select Embed & Sign.
Click Runner and go to the Build Settings tab.
In the Search Paths section configure the Library Search Paths to include the path where libyourlibrary.dylib is located.
Edit lib/main.dart.
Use DynamicLibrary.open('libyourlibrary.dylib') to dynamically link to the symbols.
Call your native function somewhere in a widget.
Run flutter run and check that your native function gets called.
Run flutter build macos to build a self-contained release version of your app.

используем файл libpdfium.dylib

для андроид проверить наличие в assets/libpdf/libpdfium_android.so, далее он сам скопируется в документ директорию проекта

для Windows в корне проекта должен лежать файл pdfium.dll, далее все произойдет само
при обновлении файлов библиотек придерживаться архитектуры на которой будет работать приложение

обновления библиотеки https://github.com/bblanchon/pdfium-binaries
