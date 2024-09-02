//+------------------------------------------------------------------+
//|                                               LiquiditySweep.mq5 |
//|                                         Copyright 2024, rpanchyk |
//|                                      https://github.com/rpanchyk |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, rpanchyk"
#property link      "https://github.com/rpanchyk"
#property version   "1.01"
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
input color InpHigherLqSwLineColor = clrGreen; // Color of higher liquidity sweep line
input color InpLowerLqSwLineColor = clrRed; // Color of lower liquidity sweep line
input ENUM_LINE_STYLE InpLineStyle = STYLE_DOT; // Line style
input int InpLineWidth = 1; // Line width

input group "Section :: Forecast";
input bool InpForecastEnabled = true; // Enable forecast of liquidity sweep
input int InpForecastBackwardLimit = 1000; // Backward bars limit
input int InpForecastFractalAdjacentBars = 4; // Fractal adjacent bars count
input color InpForecastHigherLqLineColor = clrSilver; // Color of higher liquidity line
input color InpForecastLowerLqLineColor = clrSilver; // Color of lower liquidity line
input bool InpForecastLqSwAlertEnabled = false; // Alert when liquidity has been swept

input group "Section :: Dev";
input bool InpDebugEnabled = false; // Endble debug (verbose logging)

// constants
const string LQSW_OBJECT_PREFIX = "LQSW_"; // Liquidity sweep object prefix
const string LQFC_OBJECT_PREFIX = "LQFC_"; // Liquidity forecast object prefix

// runtime
string prevForecastLiquidities[];

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
      ObjectsDeleteAll(0, LQSW_OBJECT_PREFIX);
      ObjectsDeleteAll(0, LQFC_OBJECT_PREFIX);
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
                  drawLine(LQSW_OBJECT_PREFIX, time[j], jHigherHigh, time[i], jHigherHigh, InpHigherLqSwLineColor);
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
                  drawLine(LQSW_OBJECT_PREFIX, time[j], jLowerLow, time[i], jLowerLow, InpLowerLqSwLineColor);
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

   if(InpForecastEnabled)
     {
      ObjectsDeleteAll(0, LQFC_OBJECT_PREFIX);

      int backwardLimit = MathMin(rates_total - InpForecastFractalAdjacentBars, InpForecastBackwardLimit);
      double highest = high[1];
      double lowest = low[1];
      for(int i = 1 + InpForecastFractalAdjacentBars; i < backwardLimit; i++)
        {
         if(high[i] > highest && isForecastFractal(i))
           {
            if(InpDebugEnabled)
              {
               PrintFormat("Forecast of higher liquidity at %s", TimeToString(time[i]));
              }

            drawLine(LQFC_OBJECT_PREFIX, time[i], high[i], time[0], high[i], InpForecastHigherLqLineColor);
           }

         if(low[i] < lowest && isForecastFractal(i))
           {
            if(InpDebugEnabled)
              {
               PrintFormat("Forecast of lower liquidity at %s", TimeToString(time[i]));
              }

            drawLine(LQFC_OBJECT_PREFIX, time[i], low[i], time[0], low[i], InpForecastLowerLqLineColor);
           }

         highest = high[iHighest(_Symbol, PERIOD_CURRENT, MODE_HIGH, i, 1)];
         lowest = low[iLowest(_Symbol, PERIOD_CURRENT, MODE_LOW, i, 1)];
        }


      if(InpForecastLqSwAlertEnabled)
        {
         string forecastLiquidities[];
         string tmpForecastLiquidityObjectName;
         for(int i = ObjectsTotal(0, 0, OBJ_TREND); i >= 0 ; i--)
           {
            tmpForecastLiquidityObjectName = ObjectName(0, i, 0, OBJ_TREND);
            if(StringFind(tmpForecastLiquidityObjectName, LQFC_OBJECT_PREFIX, 0) != -1)
              {
               ArrayResize(forecastLiquidities, ArraySize(forecastLiquidities) + 1);
               forecastLiquidities[ArraySize(forecastLiquidities) - 1] = tmpForecastLiquidityObjectName;
              }
           }

         for(int i = ArraySize(prevForecastLiquidities) - 1; i >= 0; i--)
           {
            bool prevForecastLiquidityFound = false;
            for(int j = ArraySize(forecastLiquidities) - 1; j >= 0; j--)
              {
               if(prevForecastLiquidities[i] == forecastLiquidities[j])
                 {
                  prevForecastLiquidityFound = true;
                  break;
                 }
              }

            if(!prevForecastLiquidityFound)
              {
               string message = "Liquidity on "
                                + StringSubstr(prevForecastLiquidities[i], StringLen(LQFC_OBJECT_PREFIX))
                                + " has been swept at "
                                + TimeToString(TimeCurrent());
               Alert(message);
               if(InpDebugEnabled)
                 {
                  Print(message);
                 }
              }
           }

         ArrayResize(prevForecastLiquidities, ArraySize(forecastLiquidities));
         ArrayCopy(prevForecastLiquidities, forecastLiquidities);
        }
     }

   return rates_total;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawLine(string objPrefix, datetime fromTime, double fromPrice, datetime toTime, double toPrice, color clr)
  {
   string objName = objPrefix + TimeToString(fromTime);
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
//|                                                                  |
//+------------------------------------------------------------------+
bool isForecastFractal(int i)
  {
   return i == iHighest(_Symbol, PERIOD_CURRENT, MODE_HIGH, InpForecastFractalAdjacentBars * 2 + 1, i - InpForecastFractalAdjacentBars)
          || i == iLowest(_Symbol, PERIOD_CURRENT, MODE_LOW, InpForecastFractalAdjacentBars * 2 + 1, i - InpForecastFractalAdjacentBars);
  }
//+------------------------------------------------------------------+
