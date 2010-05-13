

/* 
Manu Kaul and Robert Fels
1. which days has a stock +/- price change? */

create function pos_stock_dates(Charstring s) -> Date d 
 as
   select daily_date(dp)
   from  DailyPrice dp
   where price_change(dp)>0
     and s in name(stock_of(dp));

create function neg_stock_dates(Charstring s) -> Date d 
 as
   select daily_date(dp)
   from  DailyPrice dp
   where price_change(dp)<0
     and s in name(stock_of(dp));

/* test 

pos_stock_dates("Astra");

OUTPUT
|2003-12-03|
|2003-11-27|

neg_stock_dates("Astra");

OUTPUT
|2003-12-02|
|2003-11-28|
|2003-11-26|
|2003-12-08|
|2003-12-05|
|2003-12-09|
*/



/* 2. difference btw. buy-and sell-price for every day in a time period */

create function dif_buy_sell(Charstring s, Date from_date, Date till_date) -> <Date, Real> 
 as 
   select daily_date(dp),(buy(dp)-sell(dp))
   from DailyPrice dp
   where daily_date(dp)>= from_date
     and daily_date(dp)<= till_date
     and s in name(stock_of(dp));

/*test 

dif_buy_sell("Astra",date(2003,11,28),date(2003,12,2));

OUTPUT
<|2003-12-02|,-0.5>
<|2003-11-28|,-0.5>
<|2003-12-01|,-0.5>
*/

/* 3. values of stocks of portfolio at a given date */

create function value_stocks(Charstring pf, Date d) -> <Charstring , Real>
 as
  groupby(
   (select name(s), amount * sell(dp)
   from DailyPrice dp, Portfolio po, Stock s, Integer amount, Date dat
   where name(po)=pf
     and <s,amount,dat> in own_detail(po)
     and dat <=d 
     and daily_date(dp)= d
     and s in stock_of(dp)),#'sum');

/* test

value_stocks("Manu", date(2003,11,27));

OUTPUT
<"Ericsson",1240.0>
<"Astra",104550.0>

value_stocks("Robert",date(2003,12,8));

*/

/*4. value of the hole portfolio */

create function value_total(Charstring pf) -> <Charstring,Real>
  as 
   groupby(
    (select "total",r
     from Charstring s, Real r
     where <s,r> in value_stocks(pf,maxagg(select daily_date(dp) from DailyPrice dp))
    ),#'sum');

/* test 

value_total("Robert");

OUTPUT
<"total",4165.0>

value_total("Manu");

*/

/* 5. development of portfolio stocks */
/*a)*/
create function stock_dev(Stock s,Date from_date, Date till_date) -> <Charstring, Real, Real>
 as
   select name(s), buy(dp2)-buy(dp1), sell(dp2)-sell(dp1)
   from  DailyPrice dp1, DailyPrice dp2, Stock s2
   where daily_date(dp1)= from_date
     and daily_date(dp2)= till_date
     and s in stock_of(dp1)
     and s2 in stock_of(dp2)
     and name(s)=name(s2);

/*test

stock_dev(:eric,date(2003,12,3),date(2003,12,8));

*/

/*returns the stocks which are owned by a portfolio(without duplicates)*/ 
create function get_stock_of_portfolio(Charstring pf) -> Stock s
 as 
   select distinct s
   from Portfolio po
   where name(po)=pf
     and s in own_stock(po);

/*give stock development for each stock in the portfolio*/
create function portfolio_stock_dev(Charstring pf,Date from_date, Date till_date) -> <Charstring,Real,Real>
 as 
   select name(s),b, se
   from   Portfolio po, Stock s, Real b, Real se
   where  name(po)=pf
      and s in get_stock_of_portfolio(pf)
      and <name(s),b,se> in stock_dev(s,from_date,till_date);

/*test

/*ok*/
portfolio_stock_dev("Manu",date(2003,12,2),date(2003,12,2));

portfolio_stock_dev("Manu",date(2003,12,2),date(2003,12,8));

OUTPUT:
<"Astra",-5.0,-5.0>
<"Ericsson",-0.4,-0.4>

portfolio_stock_dev("Robert",date(2003,12,3),date(2003,12,3));

/*ok*/
portfolio_stock_dev("Manu",date(2003,11,26),date(2003,11,27));

/*no data --> return empty ok */
portfolio_stock_dev("Manu",date(2003,11,25),date(2003,11,26));

*/



/*b)*/
create function stock_dev_percent(Stock s,Date from_date, Date till_date) -> <Charstring, Real, Real>
 as
   select name(s), (buy(dp2)-buy(dp1))/sell(dp1), (sell(dp2)-sell(dp1))/sell(dp1)
   from  DailyPrice dp1, DailyPrice dp2, Stock s2
   where daily_date(dp1)= from_date
     and daily_date(dp2)= till_date
     and s in stock_of(dp1)
     and s2 in stock_of(dp2)
     and name(s)=name(s2);

/*test

stock_dev_percent(:eric,date(2003,12,3),date(2003,12,8));

*/
/*give percental stock dev. of each stock in a portfolio*/
create function portfolio_stock_dev_percent(Charstring pf,Date from_date, Date till_date) -> <Charstring,Real,Real>
 as 
   select name(s),b, se
   from   Portfolio po, Stock s, Real b, Real se
   where  name(po)=pf
      and s in get_stock_of_portfolio(pf)
      and <name(s),b,se> in stock_dev_percent(s,from_date,till_date);

/*test

/*ok*/
portfolio_stock_dev_percent("Manu",date(2003,12,2),date(2003,12,2));

portfolio_stock_dev_percent("Manu",date(2003,12,2),date(2003,12,8));

OUTPUT
<"Astra",-0.0145772594752187,-0.0145772594752187>
<"Ericsson",-0.0317460317460318,-0.0317460317460318>
*/

/*c give the value of one stock in portfolio, regarding to the date range*/
create function portfolio_dev(Charstring pf, Charstring s, Date from_date, Date till_date) -> <Charstring,Real>
 as 
   select c, t - (f)
    from Real t, Real f, Charstring c
    where <c,t> in value_stocks((pf),till_date)
      and <c,f> in value_stocks((pf),from_date)
      and s=c
   ;

/* test

portfolio_dev("Manu","Ericsson",date(2003,12,3),date(2003,12,8));

OUTPUT
<"Ericsson",10330.0>
¨*/

/*d index*/
create function compare_index(Stock s ,Charstring index, Date from_date, Date till_date)-> <Charstring,Real,Real> /*stockname,sellprice,index*/
 as
   select name(s),sell(dp2)- sell(dp1),value(i2)-value(i1)
   from  DailyPrice dp1, DailyPrice dp2, Stock s2, Index i1, Index i2 
   where daily_date(dp1) =from_date
     and daily_date(dp2) =till_date
     and s in stock_of(dp1)
     and s2 in stock_of(dp2)
     and name(s)=name(s2)
     and name(i1)=index
     and name(i2)=index
     and daily_date(i1) = daily_date(dp1)
     and daily_date(i2) = daily_date(dp2);

create function portfolio_compare_index(Charstring pf,Charstring index, Date from_date, Date till_date)-> <Charstring,Real,Real>
 as 
   select name(s),se, i
   from   Portfolio po, Stock s, Real i, Real se
   where  name(po)=pf
      and s in get_stock_of_portfolio(pf)
      and <name(s),se,i> in compare_index(s, index,from_date,till_date);

/* test

portfolio_compare_index("Manu","Generalindex",date(2003,12,3),date(2003,12,8));

OUTPUT:
<"Astra",-7.5,-1.62>
<"Ericsson",-0.4,-1.62>
*/

/* 6. Comparison of the dev. of 2 stocks */

create function stock_dev_compare(Stock s1,Stock s2,Date from_date, Date till_date) 
				-> Bag of <Vector,Vector>
 as 
   select {c,b,se},{c2,b2,se2}
   from Charstring c, Charstring c2, Real b, Real b2, Real se, Real se2
   where <c,b,se> in stock_dev(s1,from_date,till_date)
     and <c2,b2,se2> in stock_dev(s2,from_date,till_date);

/*test

stock_dev_compare(:eric,:astra,date(2003,12,02),date(2003,12,08));

OUTPUT
<{"Ericsson",-0.4,-0.4},{"Astra",-5.0,-5.0}>
*/














