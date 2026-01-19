#!/bin/bash
# 复制HOOPS动态库到应用包的Frameworks目录

HOOPS_SDK_PATH="${SRCROOT}/../hoops_visualize/macos/hoops_sdk/lib"
FRAMEWORKS_PATH="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"

echo "HOOPS SDK Path: ${HOOPS_SDK_PATH}"
echo "Frameworks Path: ${FRAMEWORKS_PATH}"

# 创建Frameworks目录
mkdir -p "${FRAMEWORKS_PATH}"

# 复制所有dylib文件
if [ -d "${HOOPS_SDK_PATH}" ]; then
    for dylib in "${HOOPS_SDK_PATH}"/*.dylib; do
        if [ -f "$dylib" ]; then
            echo "Copying: $(basename $dylib)"
            cp -f "$dylib" "${FRAMEWORKS_PATH}/"
        fi
    done
    echo "HOOPS libraries copied successfully"
else
    echo "Warning: HOOPS SDK path not found: ${HOOPS_SDK_PATH}"
fi
