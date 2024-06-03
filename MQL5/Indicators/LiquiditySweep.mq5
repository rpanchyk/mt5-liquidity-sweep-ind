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

// buffers
double LiquiditySweepHighBuffer[]; // price of higher liquidity sweep
double LiquiditySweepLowBuffer[]; // price of lower liquidity sweep

// config
input group "Section :: Main";
input int InpLeftBarsSkip = 1; // Skepped bars to accept liquidity sweep

input group "Section :: Style";
input color InpHigherLqSwLineColor = clrGreen; // Color of higher liquidity sweep line
input color InpLowerLqSwLineColor = clrRed; // Color of lower liquidity sweep line
input ENUM_LINE_STYLE InpLineStyle = STYLE_DOT; // Line style
input int InpLineWidth = 1; // Line width

input group "Section :: Dev";
input bool InpDebugEnabled = false; // Endble debug (verbose logging)

// constants
const string OBJECT_PREFIX = "LQSW_";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("LiquiditySweep indicator initialization started");

   ArrayInitialize(LiquiditySweepHighBuffer, NULL);
   ArrayInitialize(LiquiditySweepLowBuffer, NULL);

   ArraySetAsSeries(LiquiditySweepHighBuffer, true);
   ArraySetAsSeries(LiquiditySweepLowBuffer, true);

   SetIndexBuffer(0, LiquiditySweepHighBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(1, LiquiditySweepLowBuffer, INDICATOR_CALCULATIONS);

   Print("LiquiditySweep indicator initialization finished");
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print("LiquiditySweep indicator deinitialization started");

   ArrayFree(LiquiditySweepHighBuffer);
   ArrayFree(LiquiditySweepLowBuffer);

   if(!MQLInfoInteger(MQL_TESTER))
     {
      ObjectsDeleteAll(0, OBJECT_PREFIX);
     }

   Print("LiquiditySweep indicator deinitialization finished");
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

   for(int i = 1; i < limit - 1; i++)
     {
      double iHigherHigh = MathMax(high[i], low[i]);
      double iHigherLow = MathMax(open[i], close[i]);
      for(int j = i + 1; j < limit - 1; j++)
        {
         double jHigherHigh = MathMax(high[j], low[j]);
         double jHigherLow = MathMax(open[j], close[j]);
         double jLowerLow = MathMin(high[j], low[j]);

         if(jHigherHigh < iHigherHigh && jHigherHigh >= iHigherLow)
           {
            if(j - i <= InpLeftBarsSkip)
              {
               iHigherLow = jHigherHigh;
               continue;
              }

            if(jHigherHigh < MathMax(high[j + 1], low[j + 1]))
              {
               continue;
              }

            if(InpDebugEnabled)
              {
               PrintFormat("Sweep of higher liquidity at %s", TimeToString(time[j]));
              }

            LiquiditySweepHighBuffer[i] = jHigherHigh;
            drawLine(time[j], jHigherHigh, time[i], jHigherHigh, InpHigherLqSwLineColor);
            break;
           }

         if(iHigherHigh <= jHigherHigh && iHigherHigh >= jLowerLow)
           {
            break;
           }
        }

      double iLowerHigh = MathMin(open[i], close[i]);
      double iLowerLow = MathMin(high[i], low[i]);
      for(int j = i + 1; j < limit - 1; j++)
        {
         double jHigherHigh = MathMax(high[j], low[j]);
         double jLowerHigh = MathMin(open[j], close[j]);
         double jLowerLow = MathMin(high[j], low[j]);

         if(jLowerLow > iLowerLow && jLowerLow <= iLowerHigh)
           {
            if(j - i <= InpLeftBarsSkip)
              {
               jLowerHigh = jLowerLow;
               continue;
              }

            if(jLowerLow > MathMin(high[j + 1], low[j + 1]))
              {
               continue;
              }

            if(InpDebugEnabled)
              {
               PrintFormat("Sweep of lower liquidity at %s", TimeToString(time[j]));
              }

            LiquiditySweepLowBuffer[i] = jLowerLow;
            drawLine(time[j], jLowerLow, time[i], jLowerLow, InpLowerLqSwLineColor);
            break;
           }

         if(iLowerLow >= jLowerLow && iLowerLow <= jHigherHigh)
           {
            break;
           }
        }
     }

   return rates_total;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawLine(datetime fromTime, double fromPrice, datetime toTime, double toPrice, color clr)
  {
   string objName = OBJECT_PREFIX + TimeToString(fromTime);
   ObjectCreate(0, objName, OBJ_TREND, 0, fromTime, fromPrice, toTime, toPrice);
   ObjectSetInteger(0, objName, OBJPROP_RAY, false);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, InpLineStyle);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, InpLineWidth);
   ObjectSetInteger(0, objName, OBJPROP_BACK, true);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, objName, OBJPROP_HIDDEN, false);
   ObjectSetInteger(0, objName, OBJPROP_ZORDER, 0);
  }
//+------------------------------------------------------------------+
