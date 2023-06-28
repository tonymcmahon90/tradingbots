#property strict
#property indicator_chart_window
#property indicator_buffers 2 
#property indicator_color1 clrRed
#property indicator_color2 clrBlue
#property indicator_plots 2
#property indicator_type1 DRAW_ARROW
#property indicator_type2 DRAW_ARROW
#property indicator_width1 3
#property indicator_width2 3

double up[],down[],shift;

int OnInit()
{
   SetIndexArrow(0,225); // up arrow
   SetIndexArrow(1,226); // down arrow
   SetIndexBuffer(0,up,INDICATOR_DATA);
   SetIndexBuffer(1,down,INDICATOR_DATA);  
   shift=iATR(NULL,0,20,0); // draw a little above or below 
   Print(DoubleToString(shift,Digits));
   return(INIT_SUCCEEDED);
}
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], 
                const double &high[], const double &low[], const double &close[], const long &tick_volume[], const long &volume[], const int &spread[])
{
   int limit=rates_total-prev_calculated;
   if(limit==0)limit++; // always draw first candle
   limit=MathMin(limit,rates_total-2); // we use 2 bars for MACD 
   
   for(int bar=0;bar<limit;bar++) // right newest [0] to left oldest [rates_total-1]
   {
      down[bar]=up[bar]=NULL;
      if(iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_SIGNAL,bar)>iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,bar) &&
         iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_SIGNAL,bar+1)<iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,bar+1) ) down[bar]=iHigh(NULL,0,bar)+shift;
            
      if(iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_SIGNAL,bar)<iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,bar) &&
         iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_SIGNAL,bar+1)>iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,bar+1) ) up[bar]=iLow(NULL,0,bar)-shift;
   }
   
   Print(limit," ",rates_total," ",prev_calculated);
   
   return(rates_total);
}