//////////////////////////////////////////////////////////////////////////////////
//*******************************************************************************
//---
//---	author: Wu Chang Sheng
//---
//---	CreateTime:	2019/01/24
//---
//*******************************************************************************
//////////////////////////////////////////////////////////////////////////////////
#pragma once

enum cwMDAPIType :int
{
	cwMD_SIM = 0,
	cwMD_CTP,
	cwMD_QDP,
	cwMD_Femas,
	cwMD_Tap,
	cwMD_FCC,
	cwMD_FcmBC,
	cwMD_FcmSHFE,
	cwMD_FcmZCE,
	cwMD_NG,
	cwMD_QDFtd,
	cwMD_Cffexmd,
	cwMD_OesMds,
	cwMD_CNT
};
const char * g_cwGetMdApiName(cwMDAPIType apitype);

enum cwTradeAPIType :int
{
	cwTrade_SIM = 0,
	cwTrade_CTP,
	cwTrade_QDP,
	cwTrade_Femas,
	cwTrade_Rohon,
	cwTrade_ES,
	cwTrade_OesTds,
	cwTrade_CNT
};
const char * g_cwGetTradeApiName(cwTradeAPIType apitype);