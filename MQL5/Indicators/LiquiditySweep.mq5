//+------------------------------------------------------------------+
//|                                               LiquiditySweep.mq5 |
//|                                         Copyright 2024, rpanchyk |
//|                                      https://github.com/rpanchyk |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, rpanchyk"
#property link      "https://github.com/rpanchyk"
#property version   "1.00"
#property description "Indicator shows liquidity sweep"

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 1

// includes
//#include <Object.mqh>
//#include <arrays/arrayobj.mqh>

// config
input group "Section :: Main";
input int InpBarsLimit = 1000; // Bars limit to search liquidity
input group "Section :: Dev";
input bool InpDebugEnabled = true; // Endble debug (verbose logging)

// constants
const string OBJECT_PREFIX = "LQS_";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("LiquiditySweep initialization started");

//...

   Print("LiquiditySweep initialization finished");
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print("LiquiditySweep deinitialization started");

//...

   if(!MQLInfoInteger(MQL_TESTER))
     {
      ObjectsDeleteAll(0, OBJECT_PREFIX);
     }

   Print("LiquiditySweep deinitialization finished");
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(rates_total == prev_calculated)
     {
      return rates_total;
     }

   ArraySetAsSeries(time, true);
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);

   int limit = (int) MathMin(rates_total, rates_total - prev_calculated + 1);
   if(InpDebugEnabled)
     {
      PrintFormat("RatesTotal: %i, PrevCalculated: %i, Limit: %i", rates_total, prev_calculated, limit);
     }

   for(int i = 1; i < InpBarsLimit - 1; i++)
     {
      double iHigherHigh = MathMax(high[i], low[i]);
      double iHigherLow = MathMax(open[i], close[i]);
      //double iLowerHigh = MathMin(open[i], close[i]);
      //double iLowerLow = MathMin(high[i], low[i]);

      for(int j = i + 1; j < InpBarsLimit; j++)
        {
         double jHigherHigh = MathMax(high[j], low[j]);
         double jHigherLow = MathMax(open[j], close[j]);
         double jLowerHigh = MathMin(open[j], close[j]);
         double jLowerLow = MathMin(high[j], low[j]);

         if(jHigherHigh < iHigherHigh && jHigherHigh > iHigherLow)
           {
            Print("Sweep HLQ");

            if(j - i <= 5)
              {
               iHigherLow = jHigherHigh;
               continue;
              }
            
            if(jHigherHigh < MathMax(high[j + 1], low[j + 1]))
              {
               continue;
              }

            drawLine(time[j], jHigherHigh, time[i], jHigherHigh, clrBlue);
            break;
           }

         if(iHigherHigh <= jHigherHigh && iHigherHigh >= jLowerLow)
           {
            Print("break");
            break;
           }
        }
     }




//   for(int j = 1; j < InpBarsLimit; j++)
//     {
//      double higherHigh = MathMax(high[j], low[j]);
//      double higherLow = MathMax(open[j], close[j]);
//      double lowerHigh = MathMin(open[j], close[j]);
//      double lowerLow = MathMin(high[j], low[j]);
//
//      for(int i = j + 1; i < InpBarsLimit; i++)
//        {
//         double iCeil = MathMax(high[i], low[i]);
//         double iFloor = MathMin(high[i], low[i]);
//
//         double iHigherLow = MathMax(open[i], close[i]);
//         double iLowerHigh = MathMin(open[i], close[i]);
//
//         if(iCeil < higherHigh && iCeil > higherLow)
//           {
//            if(i - j == 1)
//              {
//               continue;
//              }
//            Print("high liq");
//
//            ObjectCreate(0, OBJECT_PREFIX + IntegerToString(i), OBJ_TREND, 0, time[i], iCeil, time[j], iCeil);
//            ObjectSetInteger(0, OBJECT_PREFIX + IntegerToString(i), OBJPROP_RAY, false);
//            ObjectSetInteger(0, OBJECT_PREFIX + IntegerToString(i), OBJPROP_COLOR, clrGreen);
//           }
//
//         if(iFloor < lowerHigh && iFloor > lowerLow)
//           {
//            if(i - j == 1)
//              {
//               continue;
//              }
//            Print("low liq");
//
//            ObjectCreate(0, OBJECT_PREFIX + IntegerToString(i), OBJ_TREND, 0, time[i], iFloor, time[j], iFloor);
//            ObjectSetInteger(0, OBJECT_PREFIX + IntegerToString(i), OBJPROP_RAY, false);
//            ObjectSetInteger(0, OBJECT_PREFIX + IntegerToString(i), OBJPROP_COLOR, clrRed);
//           }
//
//         if((higherHigh <= iHigherLow && higherHigh >= iLowerHigh) || (lowerLow <= iHigherLow && lowerLow >= iLowerHigh))
//           {
//            Print("break");
//            break;
//           }
//        }
//     }

   return rates_total;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawLine(datetime fromTime, double fromPrice, datetime toTime, double toPrice, color clr)
  {
   string objName = OBJECT_PREFIX + TimeToString(toTime);
   ObjectCreate(0, objName, OBJ_TREND, 0, fromTime, fromPrice, toTime, toPrice);
   ObjectSetInteger(0, objName, OBJPROP_RAY, false);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT);
  }
//+------------------------------------------------------------------+
