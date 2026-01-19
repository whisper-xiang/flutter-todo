Pod::Spec.new do |s|
  s.name             = 'hoops_visualize'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for HOOPS Visualize SDK'
  s.description      = <<-DESC
A Flutter plugin for HOOPS Visualize SDK to render CAD files (DWG, etc.) on macOS.
                       DESC
  s.homepage         = 'https://github.com/whisper-xiang/flutter-todo'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.{h,m,mm,cpp}'
  s.public_header_files = 'Classes/HoopsVisualizePlugin.h'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++',
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) MACOS_SYSTEM=1'
  }

  # HOOPS SDK配置
  hoops_sdk_path = File.expand_path('hoops_sdk', __dir__)
  
  s.preserve_paths = 'hoops_sdk/**/*'
  s.vendored_libraries = 'hoops_sdk/lib/*.dylib'
  s.xcconfig = {
    'HEADER_SEARCH_PATHS' => "$(inherited) \"#{hoops_sdk_path}/include\"",
    'LIBRARY_SEARCH_PATHS' => "$(inherited) \"#{hoops_sdk_path}/lib\"",
    'OTHER_LDFLAGS' => '$(inherited) -lhps_core -lhps_sprk -lhps_sprk_exchange -lhps_sprk_ops -lA3DLIBS',
    'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/../Frameworks @loader_path/../Frameworks'
  }
  
  # 复制HOOPS动态库到Frameworks目录
  s.script_phase = {
    :name => 'Copy HOOPS Libraries',
    :script => 'HOOPS_SDK_PATH="${PODS_TARGET_SRCROOT}/hoops_sdk/lib"; FRAMEWORKS_PATH="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"; mkdir -p "${FRAMEWORKS_PATH}"; if [ -d "${HOOPS_SDK_PATH}" ]; then for dylib in "${HOOPS_SDK_PATH}"/*.dylib; do if [ -f "$dylib" ]; then cp -f "$dylib" "${FRAMEWORKS_PATH}/"; fi; done; fi',
    :execution_position => :after_compile
  }
end
