import Foundation

enum PreviewCoverage {
    static func ignores(_ cls: String?, _ tag: String) -> Bool {
        guard let cls else { return false }
        return unread.contains(cls + "." + tag)
    }

    static func ignoresCurve(_ tag: String) -> Bool { unreadTags.contains(tag) }

    static let note = "The preview does not use this value. It is saved to the file and the game reads it"

    static let unread: Set<String> = [
        "AvfxTimelineItem.EfNo", "AvfxTimeline.LpSt", "AvfxTimeline.LpEd", "AvfxEmitter.VRX", "AvfxEmitter.VRY", "AvfxEmitter.VRZ", "AvfxEmitter.GraR", "AvfxEmitter.ARsR", "AvfxEffector.RoOT", "AvfxEffector.CCOT", "AvfxEmitterDataModel.AnX", "AvfxEmitterDataModel.AnY", "AvfxEmitterDataModel.AnZ", "AvfxEmitterDataSphereModel.AnX", "AvfxEmitterDataSphereModel.AnY", "AvfxEmitterDataSphereModel.AnZ", "AvfxEmitterDataCylinderModel.AnX", "AvfxEmitterDataCylinderModel.AnY", "AvfxEmitterDataCylinderModel.AnZ", "AvfxEmitterDataConeModel.Rad", "AvfxEmitterDataConeModel.DivX", "AvfxEmitterDataConeModel.DivY", "AvfxEmitterDataConeModel.GeMT", "AvfxEffectorDataRadialBlur.Gra", "AvfxEffectorDataRadialBlur.FaBP", "AvfxEffectorDataDirectionalBlur.FaBP", "AvfxEffectorDataGaussianBlur.Gra", "AvfxEffectorDataGaussianBlur.FaBP", "AvfxEffectorDataCameraQuake.Rot",
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
        "AvfxEffectorDataPointLight.SCDN", "AvfxEffectorDataPointLight.SCDF", "AvfxEmitter.SdNm", "AvfxEmitter.SdNo", "AvfxEmitter.bAD",
        "AvfxEmitter.PrCn", "AvfxEmitter.EmCn", "AvfxEmitter.IAX", "AvfxEmitter.IAXR", "AvfxEmitter.IAY", "AvfxEmitter.IAYR", "AvfxEmitter.IAZ",
        "AvfxEmitter.IAZR", "AvfxEmitterDataCone.AnXR", "AvfxEmitterDataCone.AnYR", "AvfxEmitterDataCone.AnZR", "AvfxEmitterDataCone.InS",
        "AvfxEmitterDataCone.InSR", "AvfxEmitterDataCone.OuS", "AvfxEmitterDataCone.OuSR", "AvfxEmitterDataConeModel.AnXR",
        "AvfxEmitterDataConeModel.AnYR", "AvfxEmitterDataConeModel.AnZR", "AvfxEmitterDataConeModel.RadR", "AvfxEmitterDataCylinderModel.AnXR",
        "AvfxEmitterDataCylinderModel.AnYR", "AvfxEmitterDataCylinderModel.AnZR", "AvfxEmitterDataModel.AnXR", "AvfxEmitterDataModel.AnYR",
        "AvfxEmitterDataModel.AnZR", "AvfxEmitterDataSphereModel.AnXR", "AvfxEmitterDataSphereModel.AnYR", "AvfxEmitterDataSphereModel.AnZR",
        "AvfxEmitterItem.LoDr", "AvfxEmitterItem.ICbB", "AvfxEmitterItem.ICSK", "AvfxEmitterItem.IPbV", "AvfxEmitterItem.IPbL",
        "AvfxEmitterItem.PrLk", "AvfxEmitterItem.StFr", "AvfxEmitterItem.bStN", "AvfxMain.Ver", "AvfxMain.bDFP", "AvfxMain.bFG", "AvfxMain.bTS",
        "AvfxMain.bASH", "AvfxMain.bCBC", "AvfxMain.bCul", "AvfxMain.CBPx", "AvfxMain.CBPy", "AvfxMain.CBPz", "AvfxMain.CBSx", "AvfxMain.CBSy",
        "AvfxMain.CBSz", "AvfxMain.ZBMs", "AvfxMain.ZBMd", "AvfxMain.bCmS", "AvfxMain.bFEL", "AvfxMain.bOSE", "AvfxMain.bOSt", "AvfxMain.NCB",
        "AvfxMain.NCE", "AvfxMain.FCB", "AvfxMain.FCE", "AvfxMain.SPHP", "AvfxMain.SKO", "AvfxMain.DwLy", "AvfxMain.DwOT", "AvfxMain.DLST",
        "AvfxMain.PL1S", "AvfxMain.PL2S", "AvfxMain.AFXe", "AvfxMain.AFXi", "AvfxMain.AFXo", "AvfxMain.AFYe", "AvfxMain.AFYi", "AvfxMain.AFYo",
        "AvfxMain.AFZe", "AvfxMain.AFZi", "AvfxMain.AFZo", "AvfxMain.bGFE", "AvfxMain.GFIM", "AvfxMain.bLTS", "AvfxMain.bAGS", "AvfxMain.APri",
        "AvfxMain.DPri", "AvfxMain.bSAB", "AvfxMain.bSBV", "AvfxMain.SBVa", "AvfxMain.bSSV", "AvfxMain.SSVa", "AvfxParticle.EnvT",
        "AvfxParticle.DirT", "AvfxParticle.UVPT", "AvfxParticle.Coll", "AvfxParticle.bS11", "AvfxParticle.ShUT", "AvfxParticle.ShR",
        "AvfxParticle.ShT", "AvfxParticle.UniV", "AvfxParticle.HybV", "AvfxParticle.bE24", "AvfxParticle.bATM", "AvfxParticle.bAFg",
        "AvfxParticle.EvAR", "AvfxParticle.DlAR", "AvfxParticle.LBAR", "AvfxParticle.DOTy", "AvfxParticleDataDecal.SS", "AvfxParticleDataDecal.DDTT",
        "AvfxParticleDataDecalRing.SS", "AvfxParticleDataDecalRing.DDTT", "AvfxParticleDataDisc.PrtC", "AvfxParticleDataDisc.PIFU",
        "AvfxParticleDataDisc.SS", "AvfxParticleDataDissolve.bRev", "AvfxParticleDataDissolve.BST", "AvfxParticleDataDissolve.NPT",
        "AvfxParticleDataDissolve.DTT", "AvfxParticleDataDissolve.EroR", "AvfxParticleDataDissolve.EdW", "AvfxParticleDataDissolve.EdC",
        "AvfxParticleDataDissolve.EdCW", "AvfxParticleDataDissolve.ECMP", "AvfxParticleDataDissolve.Int", "AvfxParticleDataModel.MNRv",
        "AvfxParticleDataModel.MNRt", "AvfxParticleDataModel.MNRi", "AvfxParticleDataModel.DLT", "AvfxParticleDataModel.PLT",
        "AvfxParticleDataModel.bLgt", "AvfxParticleDataModel.bShp", "AvfxParticleDataModel.NoAn", "AvfxParticleDataModel.Moph",
        "AvfxParticleDataModel.FrC", "AvfxParticleDataModel.FrCR", "AvfxParticleDataModel.FrRt", "AvfxParticleDataModelSkin.AuTT",
        "AvfxParticleDataModelSkin.bCM", "AvfxParticleDataModelSkin.FrC", "AvfxParticleDataModelSkin.FrCR", "AvfxParticleDataModelSkin.FrRt",
        "AvfxParticleDataModelSkin.SEM", "AvfxParticleDataModelSkin.SEMR", "AvfxParticleDataModelSkin.EEM", "AvfxParticleDataModelSkin.EEMR",
        "AvfxParticleDataModelSkin.UVPD", "AvfxParticleDataPolygon.Cnt", "AvfxParticleDataPolygon.CntR", "AvfxParticleDataPolyline.NBBA",
        "AvfxParticleDataPolyline.BWpT", "AvfxParticleDataPolyline.PnED", "AvfxParticleDataPolyline.bNtB", "AvfxParticleDataPolyline.BdWp",
        "AvfxParticleDataPolyline.bCtg", "AvfxParticleDataPolyline.bCtr", "AvfxParticleDataPolyline.TagN", "AvfxParticleDataPolyline.bSpl",
        "AvfxParticleDataPolyline.bLcl", "AvfxParticleDataPolyline.CF", "AvfxParticleDataPolyline.CFR", "AvfxParticleDataPolyline.WdR",
        "AvfxParticleDataPolyline.WdBR", "AvfxParticleDataPolyline.WdCR", "AvfxParticleDataPolyline.WdER", "AvfxParticleDataPolyline.Sft",
        "AvfxParticleDataPolyline.SftR", "AvfxParticleDataPolyline.PnDs", "AvfxParticleDataPowder.bMV", "AvfxParticleDataPowder.bLoc",
        "AvfxParticleDataPowder.bLgt", "AvfxParticleDataPowder.LgtT", "AvfxParticleDataPowder.CnOf", "AvfxParticleDataQuad.SS",
        "AvfxParticleDataQuad.bMP", "AvfxParticleSimple.SIDT", "AvfxParticleSimple.SBDT", "AvfxParticleSimple.RIX", "AvfxParticleSimple.RIY",
        "AvfxParticleSimple.RAX", "AvfxParticleSimple.RAY", "AvfxParticleSimple.RAZ", "AvfxParticleSimple.RBX", "AvfxParticleSimple.RBY",
        "AvfxParticleSimple.RVX", "AvfxParticleSimple.RVY", "AvfxParticleSimple.FltS", "AvfxParticleSimple.UvLC", "AvfxParticleSimple.VBMN",
        "AvfxParticleSimple.IRD0", "AvfxParticleSimple.IRD1", "AvfxParticleSimple.CIM", "AvfxParticleSimple.CIMR", "AvfxParticleSimple.CrLR",
        "AvfxParticleSimple.bRUV", "AvfxParticleSimple.PolT", "AvfxParticleTextureColor1.bPFC", "AvfxParticleTextureColor1.bUOS",
        "AvfxParticleTextureColor2.bPFC", "AvfxParticleTextureColor2.bUOS", "AvfxParticleTextureNormal.NPow", "AvfxParticleTextureReflection.Rate",
        "AvfxParticleTextureReflection.RPow", "AvfxParticleUvSet.CUvT", "AvfxTexture.Path", "AvfxTimeline.TICn", "AvfxTimeline.CpCn",
        "AvfxTimelineItem.Plfm",
    ]

    static let unreadTags: Set<String> = [
        "AFXe", "AFXi", "AFXo", "AFYe", "AFYi", "AFYo", "AFZe", "AFZi", "AFZo", "APri", "AStr", "Amb", "AnXR", "AnYR", "AnZR", "AttR", "AuTT", "BCT",
        "BPT", "BST", "BWpT", "BdWp", "CBPx", "CBPy", "CBPz", "CBSx", "CBSy", "CBSz", "CF", "CFR", "CGE", "CIM", "CIMR", "COF", "COFR", "CSR", "CSS",
        "CUvT", "CnOf", "Cnt", "CntR", "CoUF", "Coll", "CpCn", "CrLR", "DDTT", "DLST", "DLT", "DOTy", "DPri", "DTT", "DirT", "DlAR", "DstR", "DwLy",
        "DwOT", "ECMP", "EEM", "EEMR", "EdC", "EdCW", "EdW", "EmCn", "EnvT", "EroR", "EvAR", "FCB", "FCE", "FltS", "FrC", "FrCR", "FrRt", "GFIM",
        "HybV", "IAX", "IAXR", "IAY", "IAYR", "IAZ", "IAZR", "ICSK", "ICbB", "IPbL", "IPbV", "IRD0", "IRD1", "InS", "InSR", "Int", "LBAR", "LgtT",
        "LoDr", "MNRi", "MNRt", "MNRv", "Moph", "NBBA", "NCB", "NCE", "NPT", "NPow", "NoAn", "OuS", "OuSR", "PIFU", "PL1S", "PL2S", "PLT", "Path",
        "Plfm", "PnDs", "PnED", "PolT", "PowR", "PrCn", "PrLk", "Prp1", "Prp2", "PrpG", "PrtC", "RAX", "RAY", "RAZ", "RBX", "RBY", "RIX", "RIY",
        "RPow", "RVX", "RVY", "RadR", "Rate", "RdIR", "RdOR", "RnPT", "RnPX", "RnPY", "RnPZ", "RnRd", "RoTp", "SBDT", "SBVa", "SCDF", "SCDN", "SEM",
        "SEMR", "SIDT", "SKO", "SPHP", "SS", "SSVa", "SdNm", "SdNo", "Sft", "SftR", "ShR", "ShT", "ShUT", "SpS", "SpSR", "StFr", "TICn", "TagN",
        "UVPD", "UVPT", "UniV", "UvLC", "VBMN", "Ver", "WdBR", "WdCR", "WdER", "WdR", "ZBMd", "ZBMs", "bAD", "bAFg", "bAGS", "bAGm", "bAOV", "bASH",
        "bATM", "bBET", "bCBC", "bCM", "bChS", "bCmS", "bCtg", "bCtr", "bCul", "bDFP", "bDSE", "bE24", "bFEL", "bFG", "bFTO", "bGFE", "bIFY", "bLTS",
        "bLcl", "bLgt", "bLoc", "bMP", "bMV", "bMpS", "bMvS", "bNtB", "bOS", "bOSE", "bOSt", "bPFC", "bRUV", "bRev", "bRng", "bS11", "bSAB", "bSBV",
        "bSSV", "bSdw", "bShp", "bSpl", "bStG", "bStN", "bTS", "bTSc", "bTSd", "bTSi", "bUOS", "bVSb", "bVSc", "bVSd", "bVSi",
    ]
}
