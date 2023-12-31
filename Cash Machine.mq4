#property strict

int ticket=0,ret;
double lotsize;

input int sl=500; // Stoploss points
input int tp=500; // Takeprofit points
input int max_spread=20; // Max spread points
enum _risktype{ Cash,Lotsize,Percentage };
input _risktype risktype=Percentage;
input double risk=1; // Risk
enum _usetime{ LocalTime, // Local time
             ServerTime, // Server time             
             };
input _usetime usetime=LocalTime; // Use time
input bool usestartstop=true; // Use start and stop time
input string starttime="23:15"; // Start time
input string stoptime="14:00"; // Stop time  
input bool useclosetime=true; // Use close time
input string closetime="21:45"; // Close time

int OnInit()
{
   MathSrand(GetTickCount());
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
}
void OnTick()
{
   if(ticket==0) // no order
   {
      if(MaxSpread()) return; // check spread 
   
      if(MathRand()<16384) // true half the time
      {
         if(CalcLotsize(sl*Point()) && TradeTime())
         {   ret=OrderSend(Symbol(),OP_BUY,lotsize,Ask,5,Ask-(sl*Point()),Ask+(tp*Point()),NULL,0,0,clrNONE);
            if(ret==-1) Print("Buy error ",GetLastError()); else ticket=ret;
         }
      }  
      else // sell
      {
         if(CalcLotsize(sl*Point()) && TradeTime())
         {
            ret=OrderSend(Symbol(),OP_SELL,lotsize,Bid,5,Bid+(sl*Point()),Bid-(tp*Point()),NULL,0,0,clrNONE);
            if(ret==-1) Print("Buy error ",GetLastError()); else ticket=ret;
         }
      }
  }
  else
  {
      if(OrderSelect(ticket,SELECT_BY_TICKET)) // select order
      {
         if(OrderCloseTime()){ ticket=0; return; } // closed
         else // still open
         {
            if(CloseTime()) // check for close time
            {
               if(OrderType()==OP_BUY)
               {
                  if(OrderClose(ticket,lotsize,Bid,10,clrNONE)) ticket=0; else Print("Buy close error ",GetLastError());
               }
               else // OP_SELL
               {
                  if(OrderClose(ticket,lotsize,Ask,10,clrNONE)) ticket=0; else Print("Sell close error ",GetLastError());
               }
            }
         }         
      }
  }
}

bool CloseTime()
{
   if(!useclosetime) return false;

   datetime now=TimeCurrent(); //server time
   if(usetime==LocalTime) now=TimeLocal(); // or local time
   
   datetime close=StringToTime(closetime); // with current date   
   if(now==close) return true; else return false;
}

bool TradeTime()
{
   if(!usestartstop) return true; 

   datetime now=TimeCurrent(); //server time
   if(usetime==LocalTime) now=TimeLocal(); // or local time
      
   datetime start_time=StringToTime(starttime); // with current date
   datetime stop_time=StringToTime(stoptime); // with current date
   
   if(start_time>stop_time) // 23:15 > 14:00 goes past 00:00
   {
      if(now>=start_time || now<=stop_time) return true; else return false;   
   } 
   
   if(now>=start_time && now<=stop_time) return true; else return false;   // 08:00 < 16:30
}

bool CalcLotsize(double price_risk)
{
   if(risktype==Lotsize){ lotsize=risk; return true; }
   
   double cash_risk=risk;   
   if(risktype==Percentage) cash_risk=AccountBalance()*0.01*risk;
   
   double ticksize=SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE),tickvalue=SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_VALUE);   
   // price_risk might be 100 pips 1000 points of EURUSD i.e. 0.01000 , cash_risk might be £100    
   double ideallotsize=cash_risk/((price_risk/ticksize)*tickvalue);   
   if(ideallotsize<SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN)) return false; // not enough money for minimum trade   
   double tmp=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
   
   while(true)
   {
      if(tmp+SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP)>ideallotsize) break; // gone over
      if(tmp+SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP)>SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX)) break; // max
      tmp+=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP); // next step
   }
   
   lotsize=NormalizeDouble(tmp,2);   
   return true;
}

bool MaxSpread()
{
   double spread=(SymbolInfoDouble(Symbol(),SYMBOL_ASK)-SymbolInfoDouble(Symbol(),SYMBOL_BID))/Point();   
   if((int)spread>max_spread) return true; else return false; // true if too big spread
}