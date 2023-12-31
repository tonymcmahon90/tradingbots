// 29th June 2023
// Idea, is there any consistency on any time frame at specific time of day to buy or sell ? 

#include <Trade/Trade.mqh> // Standard Library Trade Class
CTrade trade;

input group "Risk"
input int stoploss=500; // Stoploss points or 0
input int takeprofit=500; // Takeprofit points or 0 
input double percentrisk=0.25; // Risk %
input double fixedlotsize=0; // 0 to use % 
input int maxspread=20; // Maximum spread points 
input group "Timing"
input int entry_time=480; // Entry time 480=8am
input int trade_time=60;  // Trade time 60=60mins
input bool _mode=true; // Mode true=Buy false=Sell 

ulong _ticket=0; // ticket 

int OnInit()
{ 
   return(INIT_SUCCEEDED);
}

void OnTick()
{
   double entry,lotsize,_tp,_sl;
   MqlDateTime mt;
   TimeCurrent(mt);
   int t=mt.hour*60+mt.min;
   
   if(_ticket==0) // no ticket so wait for entry
   {
      if(t==entry_time) // time to enter trade
      {      
         if((SymbolInfoDouble(Symbol(),SYMBOL_ASK)-SymbolInfoDouble(Symbol(),SYMBOL_BID))>(maxspread*Point())) return; // maximum spread 
         
         if(_mode) // buy
         {
            entry=SymbolInfoDouble(Symbol(),SYMBOL_ASK); 
            if(takeprofit)_tp=entry+(takeprofit*Point()); else _tp=0;
            if(stoploss)_sl=entry-(stoploss*Point()); else _sl=0;
            lotsize=CalcLotsize(stoploss*Point()); // 500 points = 50 pips = 0.00500 for EURUSD 5 digits or 0.500 for USDJPY 3 digits 
            if(lotsize!=0)
            {
               if(trade.Buy(lotsize,NULL,entry,_sl,_tp,NULL))
               {
                  if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _ticket=trade.ResultOrder();
                  Print("Buy ",trade.ResultRetcode()," ",_ticket," Time ",t);
               }
               else Print("Buy Error ",GetLastError());
            }
         }
         else // sell 
         {
            entry=SymbolInfoDouble(Symbol(),SYMBOL_BID);
            if(takeprofit)_tp=entry-(takeprofit*Point()); else _tp=0;
            if(stoploss)_sl=entry+(stoploss*Point()); else _sl=0;
            lotsize=CalcLotsize(stoploss*Point()); // 500 points = 50 pips = 0.00500 for EURUSD 5 digits or 0.500 for USDJPY 3 digits 
            if(lotsize!=0)
            {
               if(trade.Sell(lotsize,NULL,entry,_sl,_tp,NULL))
               {
                  if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _ticket=trade.ResultOrder();
                  Print("Sell ",trade.ResultRetcode()," ",_ticket," Time ",t);
               }
               else Print("Sell Error ",GetLastError());
            }
         }
      }               
   }
   else // do have a ticket 
   {
      if(t==entry_time+trade_time) // exit
      {
         if(PositionSelectByTicket(_ticket))
         {
            trade.PositionClose(_ticket,ULONG_MAX); // close
            Print("Close ",trade.ResultRetcode()," ",_ticket," Time ",t);
            _ticket=0;
         }
         else Print("Close ",_ticket," Error ",GetLastError());
      }  
       
      if(!PositionSelectByTicket(_ticket))_ticket=0; // if we can't select the ticket it's probably closed so reset _ticket to 0 
   }   
}

double CalcLotsize(double pricerisk) // i.e. 0.00100 is risk 100 points, 10 pips
{
   if(fixedlotsize) return fixedlotsize;

   double ticksrisked=pricerisk/SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE); // 0.00100 / 0.00001 = 100 ticks ( tick is usually same as point ) 
   double tickvalue=SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_VALUE); // cash risked in account currency per 1.00 per tick , EURUSD ~ £0.75 per 1.00 per 0.00001 tick 
   double cashrisk=AccountInfoDouble(ACCOUNT_BALANCE)*percentrisk*0.01; // £10000 * 1 * 1%(0.01) = £100
   double ideallotsize=cashrisk/(ticksrisked*tickvalue); // £100 / ( 100 * 0.75 ) = 1.33 > $130 > $1.30 per point > $13/pip for 10 pips risked
   
   double tmplotsize=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN); // start at i.e. 0.01 
   double tmp=0;
   
   while(true) // find nearest correct lotsize < 1%
   {
      if(tmplotsize>ideallotsize) break;
      if(tmplotsize>SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX)) break; // maximum trade size   
      tmp=tmplotsize; // update
      tmplotsize+=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP); // next step
   }
   
   Print("Ideal lotsize=",DoubleToString(ideallotsize,4)," Rounded down to ",DoubleToString(tmp,2)); // show ideal size 
   return(tmp);
}
