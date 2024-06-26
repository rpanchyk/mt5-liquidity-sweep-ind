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
#property indicator_buffers 4
#property indicator_plots 1

// buffers
double LiquiditySweepHighPriceBuffer[]; // price of higher liquidity sweep
double LiquiditySweepHighBarsBuffer[]; // number of bars of higher liquidity sweep
double LiquiditySweepLowPriceBuffer[]; // price of lower liquidity sweep
double LiquiditySweepLowBarsBuffer[]; // number of bars of lower liquidity sweep

// config
input group "Section :: Main";
input int InpLeftBarsSkip = 1; // Skipped bars to accept liquidity sweep

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

   ArrayInitialize(LiquiditySweepHighPriceBuffer, NULL);
   ArrayInitialize(LiquiditySweepHighBarsBuffer, NULL);
   ArrayInitialize(LiquiditySweepLowPriceBuffer, NULL);
   ArrayInitialize(LiquiditySweepLowBarsBuffer, NULL);

   ArraySetAsSeries(LiquiditySweepHighPriceBuffer, true);
   ArraySetAsSeries(LiquiditySweepHighBarsBuffer, true);
   ArraySetAsSeries(LiquiditySweepLowPriceBuffer, true);
   ArraySetAsSeries(LiquiditySweepLowBarsBuffer, true);

   SetIndexBuffer(0, LiquiditySweepHighPriceBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(1, LiquiditySweepHighBarsBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(2, LiquiditySweepLowPriceBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, LiquiditySweepLowBarsBuffer, INDICATOR_CALCULATIONS);

   Print("LiquiditySweep indicator initialization finished");
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print("LiquiditySweep indicator deinitialization started");

   ArrayFree(LiquiditySweepHighPriceBuffer);
   ArrayFree(LiquiditySweepHighBarsBuffer);
   ArrayFree(LiquiditySweepLowPriceBuffer);
   ArrayFree(LiquiditySweepLowBarsBuffer);

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

   for(int i = 1; i < limit; i++)
     {
      double iHigherHigh = high[i];
      double iHigherLow = MathMax(open[i], close[i]);
      double iLowerHigh = MathMin(open[i], close[i]);
      double iLowerLow = low[i];

      bool higherLiquiditySweepIdentificationFinished = false;
      bool lowerLiquiditySweepIdentificationFinished = false;

      for(int j = i + 1; j < rates_total - 1; j++)
        {
         double jHigherHigh = high[j];
         double jHigherLow = MathMax(open[j], close[j]);
         double jLowerHigh = MathMin(open[j], close[j]);
         double jLowerLow = low[j];

         // Higher liquidity sweep identification
         if(!higherLiquiditySweepIdentificationFinished)
           {
            if(jHigherHigh < iHigherHigh && jHigherHigh >= iHigherLow)
              {
               bool skip = j - i <= InpLeftBarsSkip;
               if(skip)
                 {
                  iHigherLow = MathMax(iHigherLow, jHigherHigh);
                 }

               if(!skip && j == iHighest(_Symbol, PERIOD_CURRENT, MODE_HIGH, j - i + 1, i + 1))
                 {
                  if(InpDebugEnabled)
                    {
                     PrintFormat("Sweep of higher liquidity at %s", TimeToString(time[j]));
                    }

                  LiquiditySweepHighPriceBuffer[i] = jHigherHigh;
                  LiquiditySweepHighBarsBuffer[i] = j - i;
                  drawLine(time[j], jHigherHigh, time[i], jHigherHigh, InpHigherLqSwLineColor);
                 }
              }

            if(iHigherHigh <= jHigherHigh && iHigherHigh >= jLowerLow)
              {
               higherLiquiditySweepIdentificationFinished = true;
              }
           }

         // Lower liquidity sweep identification
         if(!lowerLiquiditySweepIdentificationFinished)
           {
            if(jLowerLow > iLowerLow && jLowerLow <= iLowerHigh)
              {
               bool skip = j - i <= InpLeftBarsSkip;
               if(skip)
                 {
                  iLowerHigh = MathMin(iLowerHigh, jLowerLow);
                 }

               if(!skip && j == iLowest(_Symbol, PERIOD_CURRENT, MODE_LOW, j - i + 1, i + 1))
                 {
                  if(InpDebugEnabled)
                    {
                     PrintFormat("Sweep of lower liquidity at %s", TimeToString(time[j]));
                    }

                  LiquiditySweepLowPriceBuffer[i] = jLowerLow;
                  LiquiditySweepLowBarsBuffer[i] = j - i;
                  drawLine(time[j], jLowerLow, time[i], jLowerLow, InpLowerLqSwLineColor);
                 }
              }

            if(iLowerLow >= jLowerLow && iLowerLow <= jHigherHigh)
              {
               lowerLiquiditySweepIdentificationFinished = true;
              }
           }

         if(higherLiquiditySweepIdentificationFinished && lowerLiquiditySweepIdentificationFinished)
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
