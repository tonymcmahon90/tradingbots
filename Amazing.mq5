// places pending trades 20 pips default above and below current price , stoploss 100 pips takeprofit 20 pips
// if either pending order triggers it places two new pending orders 

#include <Trade\Trade.mqh>
CTrade trade;
ulong pendingbuy=0,pendingsell=0;
double pricebuy,pricesell;

input int start_hour=0;
input int stop_hour=12;
input bool use_time=true;
input double lots=0.01; // Lot size
input int step=200; // Step in points
input int stoploss=1000; // Stoploss in points
input int takeprofit=200; // Takeprofit in points 

int OnInit()
{
   if(!AccountInfoInteger(ACCOUNT_HEDGE_ALLOWED)){ MessageBox("Need Hedging account"); return(INIT_FAILED); }   
   
   if(StringCompare(StringSubstr(_Symbol,0,6),"EURUSD",true)==0){  return(INIT_SUCCEEDED); } // 7 ic 7 xm
   if(StringCompare(StringSubstr(_Symbol,0,6),"USDJPY",true)==0){  return(INIT_SUCCEEDED); } // 0 ic 16 xm
   if(StringCompare(StringSubstr(_Symbol,0,6),"GBPUSD",true)==0){  return(INIT_SUCCEEDED); } // 18 ic 17 xm   
      
   MessageBox("EURUSD, USDJPY, GBPUSD only"); 
   return(INIT_FAILED);
}
void OnDeinit(const int reason)
{
}
void OnTick()
{  
   if(!TradeTime()) return;
   
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
   
   if(newbuy){ if(OrderSelect(pendingsell)) trade.OrderDelete(pendingsell); 
               pendingbuy=pendingsell=0; }
   if(newsell){ if(OrderSelect(pendingbuy)) trade.OrderDelete(pendingbuy); 
                pendingbuy=pendingsell=0; }
   
   if(pendingbuy==0)
   {
      if(MarketOpen()) 
      {
      trade.SetExpertMagicNumber(50);
      if(trade.BuyStop(lots,pricebuy,_Symbol,pricebuy-(stoploss*_Point),pricebuy+(takeprofit*_Point),ORDER_TIME_GTC,0,"Buystop"))
      {
         if(trade.ResultRetcode()==TRADE_RETCODE_DONE) pendingbuy=trade.ResultOrder();
      }
      }      
   }      
   
   if(pendingsell==0)
   {
      if(MarketOpen())
      {
      trade.SetExpertMagicNumber(51);
      if(trade.SellStop(lots,pricesell,_Symbol,pricesell+(stoploss*_Point),pricesell-(takeprofit*_Point),ORDER_TIME_GTC,0,"Sellstop"))
      {
         if(trade.ResultRetcode()==TRADE_RETCODE_DONE) pendingsell=trade.ResultOrder();
      }
      }      
   }
}

bool TradeTime()
{
   if(!use_time) return true;
   
   MqlDateTime t;   
   TimeToStruct(iTime(_Symbol,PERIOD_CURRENT,0),t);
      
   if(start_hour<=stop_hour) // i.e. 8am to 10pm or 12pm to 12pm for 1 hour 
   {
      if(t.hour>=start_hour && t.hour<=stop_hour) return true; else return false;
   }
   else if(start_hour>stop_hour) // i.e. 10pm to 8am
   {
      if(t.hour>=start_hour || t.hour<=stop_hour) return true; else return false;
   }
   
   return false;
}

bool MarketOpen()
{
   MqlDateTime t;   
   datetime dt=TimeCurrent(t),start,stop;   
   SymbolInfoSessionTrade(_Symbol,(ENUM_DAY_OF_WEEK)t.day_of_week,0,start,stop); 
   dt=StringToTime(TimeToString(dt,TIME_MINUTES));
   start=StringToTime(TimeToString(start,TIME_MINUTES));
   stop=StringToTime(TimeToString(stop,TIME_MINUTES));
   //Print(dt," ",start," ",stop," ",t.day_of_week);        
   if(dt>=start && dt<stop) return true; else return false;
}
