#include <Trade/Trade.mqh> // Standard Library Trade Class
CTrade trade;

ulong _ticket=0; // ticket 

input double lotsize=0.1; 
input int _stoploss=500; // Stoploss in points 
input int ema_period=10; // EMA period
input int rvi_period=10; // RVI period
input bool zero_filter=true; // Zero filter

int hMA,hRVI;
double bMA[],bRVImain[],bRVIsignal[];
bool buy=false,sell=false;

int OnInit()
{
   hMA=iMA(Symbol(),PERIOD_CURRENT,ema_period,0,MODE_EMA,PRICE_TYPICAL);
   ArraySetAsSeries(bMA,true); // right[0] to left
   hRVI=iRVI(Symbol(),PERIOD_CURRENT,rvi_period);
   ArraySetAsSeries(bRVImain,true); 
   ArraySetAsSeries(bRVIsignal,true);  
   return(INIT_SUCCEEDED);
}

bool RVIBuy()
{
   if(bRVImain[1]>0 && zero_filter) return false;
   if(bRVImain[1]>bRVIsignal[1] && bRVImain[2]<bRVIsignal[2]) return true; 
   return false;
}

bool RVISell()
{
   if(bRVImain[1]<0 && zero_filter) return false;
   if(bRVImain[1]<bRVIsignal[1] && bRVImain[2]>bRVIsignal[2]) return true; 
   return false;
}

void OnTick()
{  
   double entry;
   
   CopyBuffer(hMA,0,0,3,bMA);
   CopyBuffer(hRVI,0,0,3,bRVImain);
   CopyBuffer(hRVI,1,0,3,bRVIsignal);
   
   if(_ticket==0)
   {
      if(RVIBuy())      
      {
         if(bMA[1]<bMA[2]) return; // want slope up trend
      
         entry=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
         
         if(trade.Buy(lotsize,Symbol(),entry,entry-(_stoploss*_Point),0,NULL))
         {
            if(trade.ResultRetcode()==TRADE_RETCODE_DONE)
            {
               _ticket=trade.ResultOrder();             
               buy=true;
               return;
            }
         }         
      }
          
      if(RVISell())   
      {
         if(bMA[1]>bMA[2]) return; 
      
         entry=SymbolInfoDouble(Symbol(),SYMBOL_BID);
         if(trade.Sell(lotsize,Symbol(),entry,entry+(_stoploss*_Point),0,NULL))
         {
            if(trade.ResultRetcode()==TRADE_RETCODE_DONE)
            {
               _ticket=trade.ResultOrder();
               sell=true;
               return;
            }                        
         }
      }  
   }
   else // got _ticket 
   {      
      if(buy && RVISell()){ if(trade.PositionClose(_ticket,ULONG_MAX)){ _ticket=0; buy=false; return; } } // exit trade      
      if(sell && RVIBuy()){ if(trade.PositionClose(_ticket,ULONG_MAX)){ _ticket=0; sell=false; return; } }       
      if(!PositionSelectByTicket(_ticket)){ _ticket=0; return; } // reset   
   } 
}