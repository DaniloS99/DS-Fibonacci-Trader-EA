//+------------------------------------------------------------------+
//|                                      DS Fibonacci Trader EA 1.00 |
//|                                                  Danilo Stanisic |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Danilo Stanisic"
#property version   "1.00"

#define FIBONACCI_NAME "DS Fibonacci"

#include <Trade\Trade.mqh>
CTrade m_trade;

enum
{
   Level0 = 0,
   Level236 = 1,
   Level382 = 2,
   Level500 = 3,
   Level618 = 4,
   Level764 = 5,
   Level1 = 6
};

double g_dFiboLevel[] = { 0.0, 0.236, 0.382, 0.5, 0.618, 0.764, 1.0 };

input group "Fibonacci Properties";
input int DaysToCount = 3;
input bool IncludeTodaysCandles = true;
input bool ShowFibonacci = true;

input group "Position Management";
input bool AutoLotSize = true;
input double RiskForAutoLot = 0.02;
input double FixedLotSize = 0.02;

input group "Expert Properties";
input int ExpertID = 201228;

bool g_bIncludeTodaysCandles = true;
bool g_bShowFiboObj = true;

int g_iFiboLevels;
int g_iDaysInCandles;

double g_dFiboPrice[];

void OnInit()
{
   m_trade.SetExpertMagicNumber(ExpertID);
   
   g_bShowFiboObj = ShowFibonacci;
   
   g_iFiboLevels = ArraySize(g_dFiboLevel);
   ArrayResize(g_dFiboPrice, g_iFiboLevels);
}

void OnDeinit(const int szReason)
{
   DeleteFiboObj();
}

void OnTick()
{
   for(int i=OrdersTotal()-1; i>=0; i--)
   {
      ulong iTicket = OrderGetTicket(i);
      
      if(OrderSelect(iTicket))
      {
         if(OrderGetString(ORDER_SYMBOL) == _Symbol && OrderGetInteger(ORDER_MAGIC) == ExpertID)
         {
            m_trade.OrderDelete(iTicket);
         }
      }
   }
   
   if(Period() == PERIOD_D1)
      g_iDaysInCandles = DaysToCount;
   else if(Period() == PERIOD_H4)
      g_iDaysInCandles = DaysToCount * 6;
   else if(Period() == PERIOD_H1)
      g_iDaysInCandles = DaysToCount * 24;
   else if(Period() == PERIOD_M30)
      g_iDaysInCandles = DaysToCount * 48;
   else if(Period() == PERIOD_M15)
      g_iDaysInCandles = DaysToCount * 96;
   else if(Period() == PERIOD_M5)
      g_iDaysInCandles = DaysToCount * 288;
   else if(Period() == PERIOD_M1)
      g_iDaysInCandles = DaysToCount * 1440;
   
   if(IncludeTodaysCandles)
   {
      MqlDateTime DateTime;
      TimeToStruct(TimeCurrent(), DateTime);
      
      g_iDaysInCandles += DateTime.hour+1;
   }
   
   int iHighestCandle = iHighest(_Symbol, _Period, MODE_HIGH, g_iDaysInCandles, 0);
   int iLowestCandle = iLowest(_Symbol, _Period, MODE_LOW, g_iDaysInCandles, 0);
   
   MqlRates PriceData[];
   ArraySetAsSeries(PriceData, true);
   CopyRates(_Symbol, _Period, 0, g_iDaysInCandles, PriceData);
   
   if(g_bShowFiboObj)
   {
      DeleteFiboObj();
      CreateFiboObj(PriceData[iHighestCandle].time, PriceData[iHighestCandle].high, PriceData[iLowestCandle].time, PriceData[iLowestCandle].low);
   }
   
   if(PositionSelect(_Symbol) > 0)
   {
      return;
   }
   
   for(int i=0; i<g_iFiboLevels; i++)
   {
      g_dFiboPrice[i] = NormalizeDouble(PriceData[iLowestCandle].low + ((PriceData[iHighestCandle].high - PriceData[iLowestCandle].low) * g_dFiboLevel[i]), _Digits);
   }
   
   double dLotSize = (AutoLotSize ? (NormalizeDouble((AccountInfoDouble(ACCOUNT_BALANCE) * RiskForAutoLot / 100), 2)) : FixedLotSize);
   
   if(PriceData[iHighestCandle].time < PriceData[iLowestCandle].time) // Down 0 - Up 1
   {
      if((PriceData[0].open > g_dFiboPrice[Level0]) && (PriceData[0].open < g_dFiboPrice[Level236]))
      {
         m_trade.BuyStop(dLotSize, g_dFiboPrice[Level236], _Symbol, g_dFiboPrice[Level0], g_dFiboPrice[Level382]);
         m_trade.BuyStop(dLotSize, g_dFiboPrice[Level618], _Symbol, g_dFiboPrice[Level500], g_dFiboPrice[Level764]);
      }
      
      if((PriceData[0].open > g_dFiboPrice[Level500]) && (PriceData[0].open < g_dFiboPrice[Level618]))
      {
         m_trade.BuyStop(dLotSize, g_dFiboPrice[Level618], _Symbol, g_dFiboPrice[Level500], g_dFiboPrice[Level764]);
      }
   }
   else if(PriceData[iHighestCandle].time > PriceData[iLowestCandle].time) // Down 1 - Up 0
   {
      if((PriceData[0].open < g_dFiboPrice[Level1]) && (PriceData[0].open > g_dFiboPrice[Level764]))
      {
         m_trade.SellStop(dLotSize, g_dFiboPrice[Level764], _Symbol, g_dFiboPrice[Level1], g_dFiboPrice[Level618]);
         m_trade.SellStop(dLotSize, g_dFiboPrice[Level382], _Symbol, g_dFiboPrice[Level500], g_dFiboPrice[Level236]);
      }
      
      if((PriceData[0].open < g_dFiboPrice[Level500]) && (PriceData[0].open > g_dFiboPrice[Level382]))
      {
         m_trade.SellStop(dLotSize, g_dFiboPrice[Level382], _Symbol, g_dFiboPrice[Level500], g_dFiboPrice[Level236]);
      }
   }
}

void CreateFiboObj(datetime tPrice1, double g_dFiboPrice1, datetime tPrice2, double g_dFiboPrice2)
{
   ObjectCreate(0, FIBONACCI_NAME, OBJ_FIBO, 0, tPrice1, g_dFiboPrice1, tPrice2, g_dFiboPrice2);
   ObjectSetInteger(0, FIBONACCI_NAME, OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, FIBONACCI_NAME, OBJPROP_STYLE, STYLE_DASHDOT);
   ObjectSetInteger(0, FIBONACCI_NAME, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, FIBONACCI_NAME, OBJPROP_BACK, true);
   ObjectSetInteger(0, FIBONACCI_NAME, OBJPROP_SELECTABLE, true);
   ObjectSetInteger(0, FIBONACCI_NAME, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, FIBONACCI_NAME, OBJPROP_RAY_LEFT, false);
   ObjectSetInteger(0, FIBONACCI_NAME, OBJPROP_RAY_RIGHT, true);
   ObjectSetInteger(0, FIBONACCI_NAME, OBJPROP_HIDDEN, false);
   ObjectSetInteger(0, FIBONACCI_NAME, OBJPROP_ZORDER, 0);
   ObjectSetInteger(0, FIBONACCI_NAME, OBJPROP_LEVELS, g_iFiboLevels);
   
   for(int i=0; i<g_iFiboLevels; i++)
   {
      ObjectSetDouble(0, FIBONACCI_NAME, OBJPROP_LEVELVALUE, i, g_dFiboLevel[i]);
      ObjectSetInteger(0, FIBONACCI_NAME, OBJPROP_LEVELCOLOR, i, clrYellow);
      ObjectSetInteger(0, FIBONACCI_NAME, OBJPROP_LEVELSTYLE, i, STYLE_DASHDOT);
      ObjectSetInteger(0, FIBONACCI_NAME, OBJPROP_LEVELWIDTH, i, 2);
      ObjectSetString(0, FIBONACCI_NAME, OBJPROP_LEVELTEXT, i, (string)g_dFiboLevel[i] + " %$");
   }
}

void DeleteFiboObj()
{
   for(int i=ObjectsTotal(0)-1; i>=0; i--)
      if(ObjectName(0, i) == FIBONACCI_NAME)
         ObjectDelete(0, ObjectName(0, i));
}