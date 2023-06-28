// simplest random robot, inputs, only trades if no other trades 

#property strict

input double lotsize=0.1; // Lotsize
input int stoploss=100; // Stoploss points
input int takeprofit=200; // Takeprofit points

int OnInit()
{
   MathSrand(GetTickCount());
   return(INIT_SUCCEEDED);
}
void OnTick()
{
   if(OrdersTotal()==0)   
   {
      if(MathRand()<16384)
      {
         if(OrderSend(Symbol(),OP_BUY,lotsize,Ask,10,Ask-(stoploss*Point()),Ask+(takeprofit*Point()),NULL,0,0,clrNONE)==-1) Print("Buy Error ",GetLastError());
      }
      else
      {
         if(OrderSend(Symbol(),OP_SELL,lotsize,Bid,10,Bid+(stoploss*Point()),Bid-(takeprofit*Point()),NULL,0,0,clrNONE)==-1) Print("Sell Eror ",GetLastError());
      }
   }
}
