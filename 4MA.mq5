#include <Trade/Trade.mqh> 
CTrade trade;
ulong _ticket=0;
int hMA1,hMA2,hMA3,hMA4;
double bMA1[],bMA2[],bMA3[],bMA4[];

input int ma1=20; // MA1 period
input int ma2=50; // MA2 period
input int ma3=80; // MA3 period
input int ma4=200; // MA4 period
input ENUM_MA_METHOD ma_method=MODE_EMA; // Method
input ENUM_APPLIED_PRICE ma_price=PRICE_TYPICAL; // Price
input double lotsize=0.1; // Lotsize

int OnInit()
{
   hMA1=iMA(NULL,0,ma1,0,ma_method,ma_price); ArraySetAsSeries(bMA1,true); 
   hMA2=iMA(NULL,0,ma2,0,ma_method,ma_price); ArraySetAsSeries(bMA2,true); 
   hMA3=iMA(NULL,0,ma3,0,ma_method,ma_price); ArraySetAsSeries(bMA3,true); 
   hMA4=iMA(NULL,0,ma4,0,ma_method,ma_price); ArraySetAsSeries(bMA4,true); 
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
}
void OnTick()
{
   CopyBuffer(hMA1,0,0,1,bMA1);
   CopyBuffer(hMA2,0,0,1,bMA2);
   CopyBuffer(hMA3,0,0,1,bMA3);
   CopyBuffer(hMA4,0,0,1,bMA4);
   
   static datetime t=iTime(NULL,0,0);

   if(_ticket==0) // no trade yet
   {
      // uptrend aligned 
      if(bMA1[0]>bMA2[0] && bMA2[0]>bMA3[0] && bMA3[0]>bMA4[0])
      {
         if(trade.Buy(lotsize))
         {
            if(trade.ResultRetcode()==TRADE_RETCODE_DONE){ _ticket=trade.ResultOrder(); t=iTime(NULL,0,0); }      
         }
      }
      
      // downtrend aligned 
      if(bMA1[0]<bMA2[0] && bMA2[0]<bMA3[0] && bMA3[0]<bMA4[0])
      {
         if(trade.Sell(lotsize))
         {
            if(trade.ResultRetcode()==TRADE_RETCODE_DONE){ _ticket=trade.ResultOrder(); t=iTime(NULL,0,0); }       
         }
      }
   }   
   else // got a trade
   {
      if(PositionSelectByTicket(_ticket))
      {
         if(t==iTime(NULL,0,0)) return; // don't close and open on same candle         
      
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
         {
            if(bMA1[0]>bMA2[0] && bMA2[0]>bMA3[0] && bMA3[0]>bMA4[0])
            {} // do nothing
            else
            {
               if(trade.PositionClose(_ticket,ULONG_MAX)) _ticket=0;            
            }         
         }
         else if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
         {
            if(bMA1[0]<bMA2[0] && bMA2[0]<bMA3[0] && bMA3[0]<bMA4[0])
            {} // do nothing
            else
            {
               if(trade.PositionClose(_ticket,ULONG_MAX)) _ticket=0;            
            }         
         }
      }
      else
      {
         _ticket=0; // can't select so assume closed
      }
   }
}