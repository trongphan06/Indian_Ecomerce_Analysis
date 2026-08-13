-- 20 đơn hàng gần nhất kèm tên khách hàng và tên sản phẩm
select 
	top 20
	a.Order_ID,
	b.Customer_Name,
	c.Product_Name,
	a.Total_Amount,
	a.Order_Date
from sales a
	inner join customers b on a.Customer_ID = b.Customer_ID
	inner join products c on c.Product_ID = a.Product_ID
order by a.Order_Date desc

-- Tổng doanh thu và số đơn hàng theo từng State
select
	a.State,
	count(*) as So_Don_Hang,
	sum(total_amount) as Tong_Doanh_Thu
from sales a
group by a.State
order by sum(total_amount) desc

-- Category có doanh thu trung bình mỗi đơn > 50000
select
	b.Category,
	AVG(a.Total_Amount) as Doanh_thu_Trung_binh,
	Count(*) as So_Don_Hang
from sales a
	inner join products b on b.Product_ID = a.Product_ID
group by b.Category
having AVG(a.Total_Amount) > 50000
order by AVG(a.Total_Amount) desc

-- Khách hàng có Total_Spent (lưu sẵn) khác với tổng thực tế tính từ bảng Sales -> phát hiện dữ liệu không đồng bộ
select
	a.Customer_ID,
	a.Customer_Name,
	a.Total_Spent as Tong_Luu_san,
	ISNULL(c.Tong_Chi_Thuc_te, 0) as Tong_Thuc_te,
	a.Total_Spent - ISNULL(c.Tong_Chi_Thuc_te, 0) as Chenh_lech
from customers a
	left join (
	select b.Customer_ID, SUM(Total_Amount) as Tong_Chi_Thuc_te
	from sales b
	group by Customer_ID
	) c on c.Customer_ID = a.Customer_ID
where ABS(a.Total_Spent - ISNULL(c.Tong_Chi_Thuc_te, 0)) > 0.01
order by Chenh_lech desc

-- Top 3 sản phẩm bán chạy nhất (theo Quantity) trong từng Category
with BanChay as (
	select
		p.Category,
		p.Product_Name,
		COUNT(s.Quantity) as Tong_So_Luong_Ban,
		RANK () Over (
				Partition by p.Category
				order by sum(s.Quantity) desc
			) as Hang
	from products p
		inner join sales s on s.Product_ID = p.Product_ID
	group by p.Category, p.Product_Name
	)
select *
from BanChay
where Hang <= 3
order by Category, Hang

-- Phân loại đơn hàng theo mức chi tiêu
select
	Case 
		when Total_Amount < 1000 then N'Thấp'
		when Total_Amount between 1000 and 10000 then N'Trung bình'
		else N'Cao'
	end as Phan_Khuc_Chi_Tieu,
	count(*) as Tong_So_Luong,
	sum(Total_Amount) as Tong_Doanh_Thu
from sales
group by
	Case 
		when Total_Amount < 1000 then N'Thấp'
		when Total_Amount between 1000 and 10000 then N'Trung bình'
		else N'Cao'
	end
order by Tong_Doanh_Thu desc

-- Thời gian giao hàng trung bình theo từng Payment_Mode
select Payment_Mode,
	avg(datediff(day, Order_Date, Delivery_Date)) as TG_giaohang_TB,
	count(*) as So_Don_Hang
from sales
where Delivery_Date is not Null
group by Payment_Mode
order by avg(datediff(day, Order_Date, Delivery_Date)) desc

-- Top 10 khách hàng chi tiêu nhiều nhất trong năm 2024
with ChiTieu2024 as (
	select 
		s.Customer_ID,
		SUM(s.Total_Amount) as Tong_ChiTieu_2024
	from sales s
	where YEAR(s.Order_Date) = 2024
	group by s.Customer_ID
	)

select top 10
	c.Customer_Name,
	c.Customer_ID,
	ct.Tong_ChiTieu_2024
from ChiTieu2024 ct
	inner join customers c on c.Customer_ID = ct.Customer_ID
order by ct.Tong_ChiTieu_2024 desc

-- So sánh Total_Amount trung bình giữa đơn có/không dùng Coupon, theo từng Customer_Tier
select
	c.Customer_Tier,
	case	
		when s.Coupon_Code IS NULL then N'Không dùng coupon'
		else N'Có dùng coupon'
		end as Nhom_Coupon,
	count(*) as So_Don_Hang,
	avg(s.Total_Amount) as Trung_binh
from sales s
	inner join customers c on c.Customer_ID = s.Customer_ID
group by c.Customer_Tier,
	case	
		when s.Coupon_Code IS NULL then N'Không dùng coupon'
		else N'Có dùng coupon' end
order by c.Customer_Tier

-- Đơn hàng đầu tiên, đơn gần nhất, và số ngày giữa 2 đơn đó
select
	c.Customer_ID,
	c.Customer_Name,
	MAX(s.Order_Date) as Don_Gan_Nhat,
	MIN(s.Order_Date) as Don_Dau_Tien,
	DATEDIFF(day, MIN(s.Order_Date), MAX(s.Order_Date)) as So_Ngay_Giua_2don,
	count(*) as So_Don_Hang
from sales s
	inner join customers c on c.Customer_ID = s.Customer_ID
group by c.Customer_ID, c.Customer_Name
having count(*) > 1
order by So_Ngay_Giua_2don desc