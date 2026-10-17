import Foundation

enum PreviewCoverage {
    static func ignores(_ cls: String?, _ tag: String) -> Bool {
        guard let cls else { return false }
        return unread.contains(cls + "." + tag)
    }

    static func ignoresCurve(_ tag: String) -> Bool { unreadTags.contains(tag) }

    static let note = "The preview does not use this value. It is saved to the file and the game reads it"

    static let unread: Set<String> = [
        "AvfxEffector.CCOT", "AvfxEffectorDataCameraQuake.Rot",
        "AvfxBinder.bStG", "AvfxBinder.bVSc", "AvfxBinder.bVSd", "AvfxBinder.bVSi", "AvfxBinder.bTSd",
        "AvfxBinder.bTSi", "AvfxBinder.bDSE", "AvfxBinder.bIFY", "AvfxBinderDataCamera.DstR", "AvfxBinderDataSpline.COFR", "AvfxBinderProperties.BCT", "AvfxEffector.bAOV", "AvfxEffector.bAGm", "AvfxEffectorDataCameraQuake.AttR",
        "AvfxEffectorDataCameraQuake.RdOR", "AvfxEffectorDataCameraQuake.RdIR", "AvfxEffectorDataDirectionalLight.PowR",
        "AvfxEffectorDataPointLight.bSdw", "AvfxEffectorDataPointLight.bChS", "AvfxEffectorDataPointLight.bMpS", "AvfxEffectorDataPointLight.bMvS",
        "AvfxEffectorDataPointLight.SCDN", "AvfxEffectorDataPointLight.SCDF", "AvfxEmitter.PrCn", "AvfxEmitter.EmCn", "AvfxMain.Ver", "AvfxMain.bDFP", "AvfxMain.bTS",
        "AvfxMain.bASH", "AvfxMain.bCBC", "AvfxMain.bCul", "AvfxMain.CBPx", "AvfxMain.CBPy", "AvfxMain.CBPz", "AvfxMain.CBSx", "AvfxMain.CBSy",
        "AvfxMain.CBSz", "AvfxMain.ZBMs", "AvfxMain.ZBMd", "AvfxMain.bFEL", "AvfxMain.bOSE", "AvfxMain.SPHP", "AvfxMain.SKO", "AvfxMain.AFZe", "AvfxMain.AFZi", "AvfxMain.AFZo", "AvfxMain.bGFE", "AvfxMain.GFIM", "AvfxMain.bLTS", "AvfxMain.APri",
        "AvfxMain.DPri", "AvfxMain.bSAB", "AvfxMain.bSBV", "AvfxMain.SBVa", "AvfxMain.bSSV", "AvfxMain.SSVa", "AvfxParticle.EnvT",
        "AvfxParticle.DirT", "AvfxParticle.UVPT", "AvfxParticle.bS11", "AvfxParticle.ShUT", "AvfxParticle.ShR",
        "AvfxParticle.ShT", "AvfxParticle.UniV", "AvfxParticle.HybV", "AvfxParticle.bE24", "AvfxParticle.bATM", "AvfxParticle.bAFg",
        "AvfxParticle.EvAR", "AvfxParticle.DlAR", "AvfxParticle.LBAR", "AvfxParticle.DOTy", "AvfxParticleDataDecal.DDTT",
        "AvfxParticleDataDecalRing.DDTT", "AvfxParticleDataDisc.SS", "AvfxParticleDataDissolve.NPT",
        "AvfxParticleDataModel.FrC", "AvfxParticleDataModel.FrCR", "AvfxParticleDataModelSkin.bCM", "AvfxParticleDataModelSkin.FrCR", "AvfxParticleDataModelSkin.FrRt",
        "AvfxParticleDataPolyline.PnED", "AvfxParticleDataPolyline.CF", "AvfxParticleDataPolyline.CFR", "AvfxParticleDataPolyline.SftR", "AvfxParticleDataPowder.bLoc",
        "AvfxParticleDataPowder.CnOf", "AvfxParticleDataQuad.SS",
        "AvfxParticleTextureColor1.bUOS",
        "AvfxParticleTextureColor2.bUOS", "AvfxParticleTextureReflection.Rate",
        "AvfxParticleTextureReflection.RPow", "AvfxTexture.Path", "AvfxTimeline.TICn", "AvfxTimeline.CpCn",
        "AvfxTimelineItem.Plfm",
    ]

    static let unreadTags: Set<String> = [
        "AFZe", "AFZi", "AFZo", "APri", "AttR", "BCT",
        "BST", "CBPx", "CBPy", "CBPz", "CBSx", "CBSy", "CBSz", "CF", "CFR", "CnOf", "CpCn", "DDTT", "DOTy", "DPri", "DirT", "DlAR", "DstR", "EmCn", "EnvT", "EvAR", "FrCR", "GFIM",
        "HybV", "LBAR", "NPT", "Path",
        "Plfm", "PnED", "PowR", "PrCn", "RPow", "Rate", "RdIR", "RdOR", "SBVa", "SCDF", "SCDN", "SKO", "SPHP", "SS", "SSVa", "SftR", "ShR", "ShT", "ShUT", "TICn", "UVPT", "UniV", "Ver", "ZBMd", "ZBMs", "bAFg", "bAGm", "bAOV", "bASH",
        "bATM", "bCBC", "bCM", "bChS", "bCul", "bDFP", "bDSE", "bE24", "bFEL", "bFTO", "bGFE", "bIFY", "bLTS",
        "bLgt", "bLoc", "bMpS", "bMvS", "bOSE", "bS11", "bSAB", "bSBV",
        "bSSV", "bSdw", "bStG", "bTS", "bTSd", "bTSi", "bUOS", "bVSc", "bVSd", "bVSi",
    ]
}
