// 28th June 2023

#include <Trade/Trade.mqh> // Standard Library Trade Class
CTrade trade;

input int stoploss=500; // Stoploss points
input int takeprofit=500; // Takeprofit points
input double percentrisk=0.25; // Risk %
input double fixedlotsize=0; // 0 to use % 
input int maxspread=20; // Maximum spread points 

ulong _ticket=0; // ticket 

int OnInit()
{
   MathSrand(GetTickCount()); // seed random number 
   return(INIT_SUCCEEDED);
}

// press 'C' to close the trade
void OnChartEvent(const int id,const long& lparam,const double& dparam,const string& sparam)
{
   if(id==CHARTEVENT_KEYDOWN && lparam=='C' && _ticket!=0) // press C to close open trade
   {
      if(PositionSelectByTicket(_ticket))
      {
         trade.PositionClose(_ticket,ULONG_MAX); // close
         Print("Close ",trade.ResultRetcode()," ",_ticket);
      }
      else Print("Close ",_ticket," Error ",GetLastError());
   }
}

void OnTick()
{
   double entry,lotsize;
   if(_ticket==0) // no ticket 
   {
      if((SymbolInfoDouble(Symbol(),SYMBOL_ASK)-SymbolInfoDouble(Symbol(),SYMBOL_BID))>(maxspread*Point())) return; // maximum spread 
      
      if(MathRand()<16384) // 0-32767 half the time buy
      {
         entry=SymbolInfoDouble(Symbol(),SYMBOL_ASK);   
         lotsize=CalcLotsize(stoploss*Point()); // 500 points = 50 pips = 0.00500 for EURUSD 5 digits or 0.500 for USDJPY 3 digits 
         if(lotsize!=0)
         {
            if(trade.Buy(lotsize,NULL,entry,entry-(stoploss*Point()),entry+(takeprofit*Point()),NULL))
            {
               if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _ticket=trade.ResultOrder();
               Print("Buy ",trade.ResultRetcode()," ",_ticket);
            }
            else Print("Buy Error ",GetLastError());
         }
      }
      else // sell 
      {
         entry=SymbolInfoDouble(Symbol(),SYMBOL_BID);
         lotsize=CalcLotsize(stoploss*Point()); // 500 points = 50 pips = 0.00500 for EURUSD 5 digits or 0.500 for USDJPY 3 digits 
         if(lotsize!=0)
         {
            if(trade.Sell(lotsize,NULL,entry,entry+(stoploss*Point()),entry-(takeprofit*Point()),NULL))
            {
               if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _ticket=trade.ResultOrder();
               Print("Sell ",trade.ResultRetcode()," ",_ticket);
            }
            else Print("Sell Error ",GetLastError());
         }
      }
   }
   else
   {
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
