// places pending trades 20 pips default above and below current price , stoploss 100 pips takeprofit 20 pips
// if either pending order triggers it places two new pending orders 

#include <Trade\Trade.mqh>
CTrade trade;
ulong pendingbuy=0,pendingsell=0;
double pricebuy,pricesell;

int hour=0;
input double lots=0.01; // Lot size
int step=200; // Step in points
int stoploss=1000; // Stoploss in points
int takeprofit=200; // Takeprofit in points 

int OnInit()
{
   if(!AccountInfoInteger(ACCOUNT_HEDGE_ALLOWED)){ MessageBox("Need Hedging account"); return(INIT_FAILED); }   
   
   if(StringCompare(StringSubstr(_Symbol,0,6),"EURUSD",true)==0){ hour=7; return(INIT_SUCCEEDED); } // 7
   if(StringCompare(StringSubstr(_Symbol,0,6),"USDJPY",true)==0){ hour=0; return(INIT_SUCCEEDED); } // 0    
   if(StringCompare(StringSubstr(_Symbol,0,6),"GBPUSD",true)==0){ hour=18; return(INIT_SUCCEEDED); } // 18    
      
   MessageBox("EURUSD, USDJPY, GBPUSD only"); 
   return(INIT_FAILED);
}
void OnDeinit(const int reason)
{
}
void OnTick()
{  
   MqlDateTime t;   
   TimeToStruct(iTime(_Symbol,PERIOD_CURRENT,0),t);
   if(t.hour!=hour) return; 
   
   // check if magic numbers still in pending orders
   ulong ticket;
   bool newbuy=true,newsell=true;
   pricebuy=SymbolInfoDouble(_Symbol,SYMBOL_ASK)+(step*_Point);  
   pricesell=SymbolInfoDouble(_Symbol,SYMBOL_BID)-(step*_Point);   
   
   for(int p=0;p<OrdersTotal();p++)
   {
      ticket=OrderGetTicket(p);
      if(ticket)
      {
         if(OrderSelect(ticket))
         {
            if(OrderGetInteger(ORDER_MAGIC)==50) newbuy=false; 
            if(OrderGetInteger(ORDER_MAGIC)==51) newsell=false;
         }      
      }
   }
   
   if(newbuy){ trade.OrderDelete(pendingsell); pendingbuy=pendingsell=0; }
   if(newsell){ trade.OrderDelete(pendingbuy); pendingbuy=pendingsell=0; }
   
   if(pendingbuy==0)
   {
      trade.SetExpertMagicNumber(50);
      if(trade.BuyStop(lots,pricebuy,_Symbol,pricebuy-(stoploss*_Point),pricebuy+(takeprofit*_Point),ORDER_TIME_GTC,0,"Buystop"))
      {
         if(trade.ResultRetcode()==TRADE_RETCODE_DONE) pendingbuy=trade.ResultOrder();
      }      
   }      
   
   if(pendingsell==0)
   {
      trade.SetExpertMagicNumber(51);
      if(trade.SellStop(lots,pricesell,_Symbol,pricesell+(stoploss*_Point),pricesell-(takeprofit*_Point),ORDER_TIME_GTC,0,"Sellstop"))
      {
         if(trade.ResultRetcode()==TRADE_RETCODE_DONE) pendingsell=trade.ResultOrder();
      }      
   }
}
