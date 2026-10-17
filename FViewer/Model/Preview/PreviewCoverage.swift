import Foundation

enum PreviewCoverage {
    static func ignores(_ cls: String?, _ tag: String) -> Bool {
        guard let cls else { return false }
        return unread.contains(cls + "." + tag)
    }

    static func ignoresCurve(_ tag: String) -> Bool { unreadTags.contains(tag) }

    static let note = "The preview does not use this value. It is saved to the file and the game reads it"

    static let unread: Set<String> = [
        "AvfxTimelineItem.EfNo", "AvfxTimeline.LpSt", "AvfxTimeline.LpEd", "AvfxEffector.CCOT", "AvfxEffectorDataGaussianBlur.Gra", "AvfxEffectorDataCameraQuake.Rot",
        "AvfxBinder.bStG", "AvfxBinder.bVSc", "AvfxBinder.bVSb", "AvfxBinder.bVSd", "AvfxBinder.bVSi", "AvfxBinder.bTSc", "AvfxBinder.bTSd",
        "AvfxBinder.bTSi", "AvfxBinder.bFTO", "AvfxBinder.bDSE", "AvfxBinder.bIFY", "AvfxBinder.bBET", "AvfxBinder.Prp1",
        "AvfxBinder.Prp2", "AvfxBinderDataCamera.DstR", "AvfxBinderDataLinear.COFR",
        "AvfxBinderDataPoint.SpS", "AvfxBinderDataPoint.SpSR", "AvfxBinderDataSpline.COFR", "AvfxBinderProperties.CoUF", "AvfxBinderProperties.bRng",
        "AvfxBinderProperties.RnPT", "AvfxBinderProperties.RnPX", "AvfxBinderProperties.RnPY", "AvfxBinderProperties.RnPZ",
        "AvfxBinderProperties.RnRd", "AvfxBinderProperties.BCT", "AvfxEffector.bAOV", "AvfxEffector.bAGm", "AvfxEffectorDataCameraQuake.AttR",
        "AvfxEffectorDataCameraQuake.RdOR", "AvfxEffectorDataCameraQuake.RdIR", "AvfxEffectorDataChromaticAberration.CSR",
        "AvfxEffectorDataChromaticAberration.CSS", "AvfxEffectorDataChromaticAberration.CGE", "AvfxEffectorDataDirectionalBlur.AStr",
        "AvfxEffectorDataDirectionalBlur.bOS", "AvfxEffectorDataDirectionalLight.PowR",
        "AvfxEffectorDataPointLight.bSdw", "AvfxEffectorDataPointLight.bChS", "AvfxEffectorDataPointLight.bMpS", "AvfxEffectorDataPointLight.bMvS",
        "AvfxEffectorDataPointLight.SCDN", "AvfxEffectorDataPointLight.SCDF", "AvfxEmitter.PrCn", "AvfxEmitter.EmCn", "AvfxEmitterItem.ICSK", "AvfxMain.Ver", "AvfxMain.bDFP", "AvfxMain.bFG", "AvfxMain.bTS",
        "AvfxMain.bASH", "AvfxMain.bCBC", "AvfxMain.bCul", "AvfxMain.CBPx", "AvfxMain.CBPy", "AvfxMain.CBPz", "AvfxMain.CBSx", "AvfxMain.CBSy",
        "AvfxMain.CBSz", "AvfxMain.ZBMs", "AvfxMain.ZBMd", "AvfxMain.bCmS", "AvfxMain.bFEL", "AvfxMain.bOSE", "AvfxMain.SPHP", "AvfxMain.SKO", "AvfxMain.PL1S", "AvfxMain.PL2S", "AvfxMain.AFZe", "AvfxMain.AFZi", "AvfxMain.AFZo", "AvfxMain.bGFE", "AvfxMain.GFIM", "AvfxMain.bLTS", "AvfxMain.bAGS", "AvfxMain.APri",
        "AvfxMain.DPri", "AvfxMain.bSAB", "AvfxMain.bSBV", "AvfxMain.SBVa", "AvfxMain.bSSV", "AvfxMain.SSVa", "AvfxParticle.EnvT",
        "AvfxParticle.DirT", "AvfxParticle.UVPT", "AvfxParticle.bS11", "AvfxParticle.ShUT", "AvfxParticle.ShR",
        "AvfxParticle.ShT", "AvfxParticle.UniV", "AvfxParticle.HybV", "AvfxParticle.bE24", "AvfxParticle.bATM", "AvfxParticle.bAFg",
        "AvfxParticle.EvAR", "AvfxParticle.DlAR", "AvfxParticle.LBAR", "AvfxParticle.DOTy", "AvfxParticleDataDecal.SS", "AvfxParticleDataDecal.DDTT",
        "AvfxParticleDataDecalRing.SS", "AvfxParticleDataDecalRing.DDTT", "AvfxParticleDataDisc.PrtC", "AvfxParticleDataDisc.PIFU",
        "AvfxParticleDataDisc.SS", "AvfxParticleDataDissolve.BST", "AvfxParticleDataDissolve.NPT",
        "AvfxParticleDataDissolve.EdC",
        "AvfxParticleDataDissolve.EdCW", "AvfxParticleDataDissolve.ECMP", "AvfxParticleDataModel.PLT",
        "AvfxParticleDataModel.NoAn", "AvfxParticleDataModel.FrC", "AvfxParticleDataModel.FrCR", "AvfxParticleDataModel.FrRt", "AvfxParticleDataModelSkin.bCM", "AvfxParticleDataModelSkin.FrC", "AvfxParticleDataModelSkin.FrCR", "AvfxParticleDataModelSkin.FrRt",
        "AvfxParticleDataModelSkin.SEM", "AvfxParticleDataModelSkin.SEMR", "AvfxParticleDataModelSkin.EEM", "AvfxParticleDataModelSkin.EEMR",
        "AvfxParticleDataModelSkin.UVPD", "AvfxParticleDataPolygon.Cnt", "AvfxParticleDataPolygon.CntR", "AvfxParticleDataPolyline.BWpT", "AvfxParticleDataPolyline.PnED", "AvfxParticleDataPolyline.BdWp",
        "AvfxParticleDataPolyline.TagN", "AvfxParticleDataPolyline.bLcl", "AvfxParticleDataPolyline.CF", "AvfxParticleDataPolyline.CFR", "AvfxParticleDataPolyline.SftR", "AvfxParticleDataPolyline.PnDs", "AvfxParticleDataPowder.bMV", "AvfxParticleDataPowder.bLoc",
        "AvfxParticleDataPowder.bLgt", "AvfxParticleDataPowder.LgtT", "AvfxParticleDataPowder.CnOf", "AvfxParticleDataQuad.SS",
        "AvfxParticleDataQuad.bMP", "AvfxParticleSimple.SBDT", "AvfxParticleSimple.RIX", "AvfxParticleSimple.RIY",
        "AvfxParticleSimple.RAX", "AvfxParticleSimple.RAY", "AvfxParticleSimple.RBX", "AvfxParticleSimple.RBY",
        "AvfxParticleSimple.RVX", "AvfxParticleSimple.RVY", "AvfxParticleSimple.UvLC", "AvfxParticleSimple.CIM", "AvfxParticleSimple.CIMR", "AvfxParticleSimple.bRUV", "AvfxParticleSimple.PolT", "AvfxParticleTextureColor1.bUOS",
        "AvfxParticleTextureColor2.bUOS", "AvfxParticleTextureNormal.NPow", "AvfxParticleTextureReflection.Rate",
        "AvfxParticleTextureReflection.RPow", "AvfxTexture.Path", "AvfxTimeline.TICn", "AvfxTimeline.CpCn",
        "AvfxTimelineItem.Plfm",
    ]

    static let unreadTags: Set<String> = [
        "AFZe", "AFZi", "AFZo", "APri", "AStr", "AttR", "BCT",
        "BST", "BWpT", "BdWp", "CBPx", "CBPy", "CBPz", "CBSx", "CBSy", "CBSz", "CF", "CFR", "CGE", "CIM", "CIMR", "COFR", "CSR", "CSS",
        "CnOf", "Cnt", "CntR", "CoUF", "CpCn", "DDTT", "DOTy", "DPri", "DirT", "DlAR", "DstR", "ECMP", "EEM", "EEMR", "EdC", "EdCW", "EmCn", "EnvT", "EvAR", "FrC", "FrCR", "FrRt", "GFIM",
        "HybV", "ICSK", "LBAR", "LgtT",
        "NPT", "NPow", "NoAn", "PIFU", "PL1S", "PL2S", "PLT", "Path",
        "Plfm", "PnDs", "PnED", "PolT", "PowR", "PrCn", "Prp1", "Prp2", "PrtC", "RAX", "RAY", "RBX", "RBY", "RIX", "RIY",
        "RPow", "RVX", "RVY", "Rate", "RdIR", "RdOR", "RnPT", "RnPX", "RnPY", "RnPZ", "RnRd", "SBDT", "SBVa", "SCDF", "SCDN", "SEM",
        "SEMR", "SKO", "SPHP", "SS", "SSVa", "SftR", "ShR", "ShT", "ShUT", "SpS", "SpSR", "TICn", "TagN",
        "UVPD", "UVPT", "UniV", "UvLC", "Ver", "ZBMd", "ZBMs", "bAFg", "bAGS", "bAGm", "bAOV", "bASH",
        "bATM", "bBET", "bCBC", "bCM", "bChS", "bCmS", "bCul", "bDFP", "bDSE", "bE24", "bFEL", "bFG", "bFTO", "bGFE", "bIFY", "bLTS",
        "bLcl", "bLgt", "bLoc", "bMP", "bMV", "bMpS", "bMvS", "bOS", "bOSE", "bRUV", "bRng", "bS11", "bSAB", "bSBV",
        "bSSV", "bSdw", "bStG", "bTS", "bTSc", "bTSd", "bTSi", "bUOS", "bVSb", "bVSc", "bVSd", "bVSi",
    ]
}
