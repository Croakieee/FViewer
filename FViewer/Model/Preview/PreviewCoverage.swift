import Foundation

enum PreviewCoverage {
    static func ignores(_ cls: String?, _ tag: String) -> Bool {
        guard let cls else { return false }
        return unread.contains(cls + "." + tag)
    }

    static func ignoresCurve(_ tag: String) -> Bool { unreadTags.contains(tag) }

    static let note = "The preview does not use this value. It is saved to the file and the game reads it"

    static let unread: Set<String> = [
        "AvfxTimelineItem.EfNo", "AvfxTimeline.LpSt", "AvfxTimeline.LpEd", "AvfxEffector.RoOT", "AvfxEffector.CCOT", "AvfxEffectorDataRadialBlur.Gra", "AvfxEffectorDataRadialBlur.FaBP", "AvfxEffectorDataDirectionalBlur.FaBP", "AvfxEffectorDataGaussianBlur.Gra", "AvfxEffectorDataGaussianBlur.FaBP", "AvfxEffectorDataCameraQuake.Rot",
        "AvfxBinder.bStG", "AvfxBinder.bVSc", "AvfxBinder.bVSb", "AvfxBinder.bVSd", "AvfxBinder.bVSi", "AvfxBinder.bTSc", "AvfxBinder.bTSd",
        "AvfxBinder.bTSi", "AvfxBinder.bFTO", "AvfxBinder.bDSE", "AvfxBinder.bIFY", "AvfxBinder.bBET", "AvfxBinder.RoTp", "AvfxBinder.Prp1",
        "AvfxBinder.Prp2", "AvfxBinder.PrpG", "AvfxBinderDataCamera.DstR", "AvfxBinderDataLinear.COF", "AvfxBinderDataLinear.COFR",
        "AvfxBinderDataLinearAdjust.COF", "AvfxBinderDataPoint.SpS", "AvfxBinderDataPoint.SpSR", "AvfxBinderDataSpline.COF",
        "AvfxBinderDataSpline.COFR", "AvfxBinderProperties.BPT", "AvfxBinderProperties.CoUF", "AvfxBinderProperties.bRng",
        "AvfxBinderProperties.RnPT", "AvfxBinderProperties.RnPX", "AvfxBinderProperties.RnPY", "AvfxBinderProperties.RnPZ",
        "AvfxBinderProperties.RnRd", "AvfxBinderProperties.BCT", "AvfxEffector.bAOV", "AvfxEffector.bAGm", "AvfxEffectorDataCameraQuake.AttR",
        "AvfxEffectorDataCameraQuake.RdOR", "AvfxEffectorDataCameraQuake.RdIR", "AvfxEffectorDataChromaticAberration.CSR",
        "AvfxEffectorDataChromaticAberration.CSS", "AvfxEffectorDataChromaticAberration.CGE", "AvfxEffectorDataDirectionalBlur.AStr",
        "AvfxEffectorDataDirectionalBlur.bOS", "AvfxEffectorDataDirectionalLight.Amb", "AvfxEffectorDataDirectionalLight.PowR",
        "AvfxEffectorDataPointLight.bSdw", "AvfxEffectorDataPointLight.bChS", "AvfxEffectorDataPointLight.bMpS", "AvfxEffectorDataPointLight.bMvS",
        "AvfxEffectorDataPointLight.SCDN", "AvfxEffectorDataPointLight.SCDF", "AvfxEmitter.SdNm", "AvfxEmitter.SdNo", "AvfxEmitter.PrCn", "AvfxEmitter.EmCn", "AvfxEmitterItem.ICSK", "AvfxMain.Ver", "AvfxMain.bDFP", "AvfxMain.bFG", "AvfxMain.bTS",
        "AvfxMain.bASH", "AvfxMain.bCBC", "AvfxMain.bCul", "AvfxMain.CBPx", "AvfxMain.CBPy", "AvfxMain.CBPz", "AvfxMain.CBSx", "AvfxMain.CBSy",
        "AvfxMain.CBSz", "AvfxMain.ZBMs", "AvfxMain.ZBMd", "AvfxMain.bCmS", "AvfxMain.bFEL", "AvfxMain.bOSE", "AvfxMain.bOSt", "AvfxMain.NCB",
        "AvfxMain.NCE", "AvfxMain.FCB", "AvfxMain.FCE", "AvfxMain.SPHP", "AvfxMain.SKO", "AvfxMain.DwOT", "AvfxMain.DLST",
        "AvfxMain.PL1S", "AvfxMain.PL2S", "AvfxMain.AFZe", "AvfxMain.AFZi", "AvfxMain.AFZo", "AvfxMain.bGFE", "AvfxMain.GFIM", "AvfxMain.bLTS", "AvfxMain.bAGS", "AvfxMain.APri",
        "AvfxMain.DPri", "AvfxMain.bSAB", "AvfxMain.bSBV", "AvfxMain.SBVa", "AvfxMain.bSSV", "AvfxMain.SSVa", "AvfxParticle.EnvT",
        "AvfxParticle.DirT", "AvfxParticle.UVPT", "AvfxParticle.bS11", "AvfxParticle.ShUT", "AvfxParticle.ShR",
        "AvfxParticle.ShT", "AvfxParticle.UniV", "AvfxParticle.HybV", "AvfxParticle.bE24", "AvfxParticle.bATM", "AvfxParticle.bAFg",
        "AvfxParticle.EvAR", "AvfxParticle.DlAR", "AvfxParticle.LBAR", "AvfxParticle.DOTy", "AvfxParticleDataDecal.SS", "AvfxParticleDataDecal.DDTT",
        "AvfxParticleDataDecalRing.SS", "AvfxParticleDataDecalRing.DDTT", "AvfxParticleDataDisc.PrtC", "AvfxParticleDataDisc.PIFU",
        "AvfxParticleDataDisc.SS", "AvfxParticleDataDissolve.BST", "AvfxParticleDataDissolve.NPT",
        "AvfxParticleDataDissolve.EdC",
        "AvfxParticleDataDissolve.EdCW", "AvfxParticleDataDissolve.ECMP", "AvfxParticleDataModel.MNRv",
        "AvfxParticleDataModel.MNRt", "AvfxParticleDataModel.MNRi", "AvfxParticleDataModel.DLT", "AvfxParticleDataModel.PLT",
        "AvfxParticleDataModel.bLgt", "AvfxParticleDataModel.bShp", "AvfxParticleDataModel.NoAn", "AvfxParticleDataModel.Moph",
        "AvfxParticleDataModel.FrC", "AvfxParticleDataModel.FrCR", "AvfxParticleDataModel.FrRt", "AvfxParticleDataModelSkin.bCM", "AvfxParticleDataModelSkin.FrC", "AvfxParticleDataModelSkin.FrCR", "AvfxParticleDataModelSkin.FrRt",
        "AvfxParticleDataModelSkin.SEM", "AvfxParticleDataModelSkin.SEMR", "AvfxParticleDataModelSkin.EEM", "AvfxParticleDataModelSkin.EEMR",
        "AvfxParticleDataModelSkin.UVPD", "AvfxParticleDataPolygon.Cnt", "AvfxParticleDataPolygon.CntR", "AvfxParticleDataPolyline.BWpT", "AvfxParticleDataPolyline.PnED", "AvfxParticleDataPolyline.BdWp",
        "AvfxParticleDataPolyline.bCtg", "AvfxParticleDataPolyline.bCtr", "AvfxParticleDataPolyline.TagN", "AvfxParticleDataPolyline.bLcl", "AvfxParticleDataPolyline.CF", "AvfxParticleDataPolyline.CFR", "AvfxParticleDataPolyline.Sft",
        "AvfxParticleDataPolyline.SftR", "AvfxParticleDataPolyline.PnDs", "AvfxParticleDataPowder.bMV", "AvfxParticleDataPowder.bLoc",
        "AvfxParticleDataPowder.bLgt", "AvfxParticleDataPowder.LgtT", "AvfxParticleDataPowder.CnOf", "AvfxParticleDataQuad.SS",
        "AvfxParticleDataQuad.bMP", "AvfxParticleSimple.SBDT", "AvfxParticleSimple.RIX", "AvfxParticleSimple.RIY",
        "AvfxParticleSimple.RAX", "AvfxParticleSimple.RAY", "AvfxParticleSimple.RBX", "AvfxParticleSimple.RBY",
        "AvfxParticleSimple.RVX", "AvfxParticleSimple.RVY", "AvfxParticleSimple.UvLC", "AvfxParticleSimple.CIM", "AvfxParticleSimple.CIMR", "AvfxParticleSimple.bRUV", "AvfxParticleSimple.PolT", "AvfxParticleTextureColor1.bPFC", "AvfxParticleTextureColor1.bUOS",
        "AvfxParticleTextureColor2.bPFC", "AvfxParticleTextureColor2.bUOS", "AvfxParticleTextureNormal.NPow", "AvfxParticleTextureReflection.Rate",
        "AvfxParticleTextureReflection.RPow", "AvfxTexture.Path", "AvfxTimeline.TICn", "AvfxTimeline.CpCn",
        "AvfxTimelineItem.Plfm",
    ]

    static let unreadTags: Set<String> = [
        "AFZe", "AFZi", "AFZo", "APri", "AStr", "Amb", "AttR", "BCT",
        "BPT", "BST", "BWpT", "BdWp", "CBPx", "CBPy", "CBPz", "CBSx", "CBSy", "CBSz", "CF", "CFR", "CGE", "CIM", "CIMR", "COF", "COFR", "CSR", "CSS",
        "CnOf", "Cnt", "CntR", "CoUF", "CpCn", "DDTT", "DLST", "DLT", "DOTy", "DPri", "DirT", "DlAR", "DstR", "DwOT", "ECMP", "EEM", "EEMR", "EdC", "EdCW", "EmCn", "EnvT", "EvAR", "FCB", "FCE", "FrC", "FrCR", "FrRt", "GFIM",
        "HybV", "ICSK", "LBAR", "LgtT",
        "MNRi", "MNRt", "MNRv", "Moph", "NCB", "NCE", "NPT", "NPow", "NoAn", "PIFU", "PL1S", "PL2S", "PLT", "Path",
        "Plfm", "PnDs", "PnED", "PolT", "PowR", "PrCn", "Prp1", "Prp2", "PrpG", "PrtC", "RAX", "RAY", "RBX", "RBY", "RIX", "RIY",
        "RPow", "RVX", "RVY", "Rate", "RdIR", "RdOR", "RnPT", "RnPX", "RnPY", "RnPZ", "RnRd", "RoTp", "SBDT", "SBVa", "SCDF", "SCDN", "SEM",
        "SEMR", "SKO", "SPHP", "SS", "SSVa", "SdNm", "SdNo", "Sft", "SftR", "ShR", "ShT", "ShUT", "SpS", "SpSR", "TICn", "TagN",
        "UVPD", "UVPT", "UniV", "UvLC", "Ver", "ZBMd", "ZBMs", "bAFg", "bAGS", "bAGm", "bAOV", "bASH",
        "bATM", "bBET", "bCBC", "bCM", "bChS", "bCmS", "bCtg", "bCtr", "bCul", "bDFP", "bDSE", "bE24", "bFEL", "bFG", "bFTO", "bGFE", "bIFY", "bLTS",
        "bLcl", "bLgt", "bLoc", "bMP", "bMV", "bMpS", "bMvS", "bOS", "bOSE", "bOSt", "bPFC", "bRUV", "bRng", "bS11", "bSAB", "bSBV",
        "bSSV", "bSdw", "bShp", "bStG", "bTS", "bTSc", "bTSd", "bTSi", "bUOS", "bVSb", "bVSc", "bVSd", "bVSi",
    ]
}
