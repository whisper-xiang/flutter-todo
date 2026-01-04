let sdk2dInstance = null;
let gstarSDKLoadingPromise = null;

// 图纸数据
const drawInfo = {
  fileId: 19412,
  fileName: "电磁铁.dwg",
  fileType: "dwg",
  fileSize: 62127,
  downloadUrl: null,
  browserUrl: null,
  magicBrowseUrl: "[[$fileBrowseUrl=19412]]",
  magicDownloadUrl: "[[$fileDownloadUrl=19412]]",
  ocfPath: [
    {
      layout: "*Model_Space",
      ocfUrl:
        "https://gstar-exam-offline-public-cn.51ake.com/dev/-1/ocf/2025/12/30/12097_b50bb40b82c226a8a532ef82817e54c1_Model_Space.ocf",
      txtUrl: "",
    },
    {
      layout: "*Paper_Space0",
      ocfUrl:
        "https://gstar-exam-offline-public-cn.51ake.com/dev/-1/ocf/2025/12/30/12097_b50bb40b82c226a8a532ef82817e54c1_Paper_Space0.ocf",
      txtUrl: "",
    },
    {
      layout: "*Paper_Space",
      ocfUrl:
        "https://gstar-exam-offline-public-cn.51ake.com/dev/-1/ocf/2025/12/30/12097_b50bb40b82c226a8a532ef82817e54c1_Paper_Space.ocf",
      txtUrl: "",
    },
  ],
  fileUsage: null,
  businessModule: 1,
  type: "2d",
};

const getOcfData = async (ocfUrl) => {
  try {
    const res = await fetch(ocfUrl, {
      method: "GET",
      headers: {
        "Content-Type": "application/octet-stream",
      },
    });
    const ocfData = await res.arrayBuffer();
    console.log(ocfData.byteLength); // 输出 byteLength
    console.log(ocfData); // 检查实际的 ArrayBuffer 内容
    return ocfData;
  } catch (err) {
    console.error("Error fetching data:", err);
    return null;
  }
};

const switchLayout = async (data) => {
  try {
    const { ocfPath, fileId } = drawInfo;
    const layoutInfo = ocfPath.find((item) => item.layout === data.globalName);
    const bufferData = await getOcfData(layoutInfo.ocfUrl);
    console.log("bufferData", bufferData);
    if (!bufferData) {
      ElMessage.error("获取2D文件失败！");
      sdk2dInstance.Tips.closeProgress();
      return;
    }

    console.log("switchLayout", bufferData, fileId, sdk2dInstance);
    await sdk2dInstance.render("ocf", bufferData, fileId, true);
    const position = coordinate?.find((item) => item.fileId === fileId);
    if (position) {
      setDWGPreviewRange(position);
    }
  } catch (error) {
    console.error("switchLayout", error);
  }
};

const show2dDrawing = async () => {
  try {
    if (!sdk2dInstance) {
      // 只允许一个加载过程
      if (!gstarSDKLoadingPromise) {
        gstarSDKLoadingPromise = getGlobalObject(
          "/js/GStarSDK.js",
          "GStarSDK"
        ).then(() => new Promise((resolve) => setTimeout(resolve, 200)));
      }
      await gstarSDKLoadingPromise;

      // 检查 SDK 是否正确加载
      if (!window.GStarSDK || typeof window.GStarSDK !== "function") {
        console.error("GStarSDK 未正确加载");
        gstarSDKLoadingPromise = null; // 加载失败，下次还能重试
        return null;
      }

      try {
        sdk2dInstance = new window.GStarSDK({
          wrapId: "flashContent",
          language: "zh",
          toolbarHideItems: {
            save: [],
            notes: [],
            measures: [],
            special: ["switchNote"],
          },
          switchLayoutCB: switchLayout,
        });
      } catch (initError) {
        console.error("GStarSDK 初始化失败:", initError);
        return null;
      }

      if (!sdk2dInstance) {
        console.error("GStarSDK 实例创建失败");
        return null;
      }

      sdk2dInstance.enableZoom(1.5);
      sdk2dInstance.enablePan(1.0);
      try {
        const code = TOTPGenerator.getTOTP();
        console.log("code", code);
        // 渲染前需要先进行授权验证
        sdk2dInstance.setDynamicPW(code); // 前端授权验证
      } catch (error) {
        console.error("setDynamicPW", error);
      }
    }

    console.log("2D图纸", drawInfo);
    const { ocfPath } = drawInfo;
    console.log("ocfPath", ocfPath);
    if (Array.isArray(ocfPath) && ocfPath.length > 0) {
      const layoutInfo = ocfPath.find((item) =>
        /model.*space/i.test(item.layout || "")
      );
      console.log("layoutInfo", layoutInfo.layout);
      if (layoutInfo) {
        await switchLayout({ globalName: layoutInfo.layout, nickName: "" });
      } else {
        console.error("2D图纸", "未找到主图纸");
      }
    }
    return sdk2dInstance;
  } catch (error) {
    console.error("show2dDrawing", error);
    gstarSDKLoadingPromise = null; // 异常时允许下次重试
    return null;
  }
};

// 当页面加载完成后执行
window.onload = function () {
  show2dDrawing();
  console.log("Page loaded, initializing viewer...");
};
