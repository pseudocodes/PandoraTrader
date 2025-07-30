//////////////////////////////////////////////////////////////////////////////////
//*******************************************************************************
//---
//---	author: Wu Chang Sheng
//---
//--	Copyright (c) by Wu Chang Sheng. All rights reserved.
//--    Consult your license regarding permissions and restrictions.
//--
//*******************************************************************************
//////////////////////////////////////////////////////////////////////////////////

#pragma once
#include <cstdint>
#include <float.h>
#include <string.h>

class cwKindleStick
{
public:
	cwKindleStick();
	~cwKindleStick();

	enum KindlePriceType
	{
		en_Open,
		en_High,
		en_Low,
		en_Close
	};

	char				szStartTime[20];	//开始时间
	char				szEndTime[20];		//结束时间
	
	//时间戳为cwTimeStamp
	std::uint64_t		StartTime;			//开始时间戳
	std::uint64_t		EndTime;			//结束时间戳
	std::uint64_t		HighTime;			//最高价时间
	std::uint64_t		LowTime;			//最低价时间

	double				Open;				//开盘价
	double				Close;				//收盘收
	double				High;				//最高价
	double				Low;				//最低价

	std::uint64_t		TotalVolume;		//总成交
	std::uint64_t		LastVolume;			//K线成交量
	double				OpenInterest;		//持仓量
	double				TotalTurnOver;		//总成交额
	double				LastTurnOver;		//K线成交额

	static size_t GetLength()
	{
		return sizeof(cwKindleStick);
	}

	inline double GetPriceByType(KindlePriceType type)
	{
		double price = Close;
		switch (type)
		{
		case cwKindleStick::en_Open:
			price = Open;
			break;
		case cwKindleStick::en_High:
			price = High;
			break;
		case cwKindleStick::en_Low:
			price = Low;
			break;
		case cwKindleStick::en_Close:
			price = Close;
			break;
		default:
			break;
		}
		return price;
	}

	void clear()
	{
		memset(szStartTime, 0, sizeof(szStartTime));
		memset(szEndTime, 0, sizeof(szEndTime));

		StartTime = EndTime = 0;
		HighTime = LowTime = 0;
		Open = Close = 0.0;
		TotalVolume = LastVolume = 0;
		OpenInterest = 0;
		Low = DBL_MAX;
		High = -1;
		TotalTurnOver = LastTurnOver = 0.0;
	}

	cwKindleStick(std::uint64_t start, std::uint64_t end, double low, double high, double open, double close,
		std::uint64_t volume, std::uint64_t lastVolume, uint32_t interest, double turnover, double lastturnover)
		: StartTime(start)
		, EndTime(end)
		, Open(open)
		, Close(close)
		, High(high)
		, Low(low)
		, TotalVolume(volume)
		, LastVolume(lastVolume)
		, OpenInterest(interest)
		, TotalTurnOver(turnover)
		, LastTurnOver(lastturnover)
	{};
};

