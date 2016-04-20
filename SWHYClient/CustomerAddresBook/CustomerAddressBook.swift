//
//  CustomerAddressBook.swift

//  SWHYClient
//
//  Created by sunny on 5/27/15.
//  Copyright (c) 2015 DY-INFO. All rights reserved.
//

import Foundation
//@objc(CustomerAddressBook) class CustomerAddressBook: UITableViewController,UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate, UISearchDisplayDelegate,CustomerAddressBookHeaderDelegate {
@objc(CustomerAddressBook) class CustomerAddressBook: UITableViewController,UISearchBarDelegate, UISearchDisplayDelegate,CustomerAddressBookHeaderDelegate {
    //@IBOutlet var tableView: UITableView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    var itemlist = [CustomerAddressItem]()
    var grouplist = [CustomerAddressGroupItem]()
    var filteredItemList = [CustomerAddressItem]()
    var sectionInfoArray: NSMutableArray! = NSMutableArray()
    var getaddress = false
    var getdept = false
    var preopenindex = NSNotFound  //上次打开的setion
    var opensectionindex = NSNotFound
    
    var fillViewFromSql = false
    var custlevel:String = ""
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?){
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
    }
    
    convenience init() {
        self.init(nibName: "CustomerAddressBook", bundle: nil)
        //self.init(nibName: "LaunchScreen", bundle: nil)
        
        
    }
    
    required init(coder aDecoder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
        
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        
        searchBar.setShowsCancelButton(true, animated: true)
        
        //var searchBarTextField : UITextField? = nil
        for mainview in searchBar.subviews
        {
            for subview in mainview.subviews {
                if subview.isKindOfClass(UIButton)
                {
                    let cancelbutton = subview as? UIButton
                    cancelbutton?.setTitle("取消", forState: UIControlState.Normal)
                    break
                }
            }
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.title = Message.shared.curMenuItem.name
        opensectionindex = NSNotFound
        getaddress = false
        getdept = false
        
        let username:String = NSUserDefaults.standardUserDefaults().stringForKey("UserName")!
        
        
        if Message.shared.loginType == "Online" {
            //print("customer address start online data")
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "HandleNetworkResult:", name: Config.RequestTag.GetCustomerAddressBook, object: nil)
            NetworkEngine.sharedInstance.addRequestWithUrlString(Config.URL.CustomerAddressBook+"&user=\(username)", tag: Config.RequestTag.GetCustomerAddressBook,useCache:false)
            
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "HandleNetworkResult:", name: Config.RequestTag.GetCustomerAddressBook_Group, object: nil)
            NetworkEngine.sharedInstance.addRequestWithUrlString(Config.URL.CustomerAddressBook_Group+"&user=\(username)", tag: Config.RequestTag.GetCustomerAddressBook_Group,useCache:false)
        }
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        let nib = UINib(nibName:"CustomerAddressBookCell", bundle: nil)
        self.tableView.registerNib(nib, forCellReuseIdentifier: "Cell")
        self.searchDisplayController?.searchResultsTableView.registerNib(nib, forCellReuseIdentifier: "Cell")
        //self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        let nib2 = UINib(nibName:"CustomerAddressBookHeader", bundle: nil)
        self.tableView.registerNib(nib2, forHeaderFooterViewReuseIdentifier: "Header")
        
        
        // Do any additional setup after loading the view.
        
        //从SQL里取得表信息并加载
        if let data:AnyObject = DBAdapter.shared.queryCustomerAddressList("'1'=?", paralist: ["1"]) {
            //self.fillViewFromSql = true
            self.itemlist = data as! [CustomerAddressItem]
            //print("从sql里取客户通讯录\(self.itemlist.count)")
            self.getaddress = true
        }
        if let deptdata:AnyObject = DBAdapter.shared.queryCustomerAddressGroupList("'1'=?", paralist: ["1"]) {
            //self.fillViewFromSql = true
            self.grouplist = deptdata as! [CustomerAddressGroupItem]
            self.getdept = true
            
        }
        //println("get SQL表信息 部门个数 \(self.grouplist.count) , SQL 人员个数 \(self.itemlist.count)")
        if self.getaddress == true && self.getdept == true {
            //此处加载视图  已经获得所有通讯录和部门信息
            //println("======================load view from sql=================")
            self.fillViewFromSql = true
            ComputeAddressInfo()
        }else{
            if Message.shared.loginType != "Online" {
                //println("=====客户通讯录未初始化")
                PKNotification.toast("客户通讯录还未首次在线访问，无法提供离线数据！")
            }else{
                PKNotification.toast("客户通讯录首次访问，数据加载中！")
            }
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let backitem = UIBarButtonItem(title: Config.UI.PreNavItem, style: UIBarButtonItemStyle.Plain, target: self, action: "returnNavView")
        self.navigationItem.leftBarButtonItem = backitem
        
        let storyboard = UIStoryboard(name: "Setting", bundle: nil)
        let customerAddressViewController = storyboard.instantiateViewControllerWithIdentifier("CustomerAddresMenuViewController") as! CustomerAddressMenuViewController
        self.slideMenuController()?.changeRightViewController(customerAddressViewController, closeRight: true)
        self.setNavigationBarItem()
        
        //self.searchDisplayController?.setActive(true, animated: true)
        
        }
    
  
    
    func returnNavView(){
        print("click return button")
        self.navigationController?.popViewControllerAnimated(true)
        
    }
    
    func HandleNetworkResult(notify:NSNotification)
    {
        //print("取得在线数据\(notify.name)")
        NSNotificationCenter.defaultCenter().removeObserver(self, name: notify.name, object: nil)
        
        let result:Result = notify.valueForKey("object") as! Result
        if result.status == "Error" {
            PKNotification.toast(result.message)
        }else if result.status=="OK"{
            //println ("++++get+++++\(notify.name)")
            if notify.name == Config.RequestTag.GetCustomerAddressBook {
                self.itemlist = result.userinfo as! [CustomerAddressItem]
                self.getaddress = true
                
                DBAdapter.shared.syncCustomerAddressList(self.itemlist)
                
                
            }else if notify.name == Config.RequestTag.GetCustomerAddressBook_Group{
                //println("开始获取在线部门数")
                self.grouplist = result.userinfo as! [CustomerAddressGroupItem]
                self.getdept = true
                DBAdapter.shared.syncCustomerAddressGroupList(self.grouplist)
                 
            }
            if self.fillViewFromSql == false {
                if self.getaddress == true && self.getdept == true {
                    //此处加载视图  已经获得所有通讯录和部门信息
                    //print("没有从SQL中取得数据，通过在线数据显示客户通讯录")
                    ComputeAddressInfo()
                }
            }
        }
    }
    
    
    
    func ComputeAddressInfo() {
        //print("Start Compute -------------------\(self.custlevel)------------->>")
        /*
        for group in self.grouplist{
            group.addresslist = [CustomerAddressItem]() 
        }
        */
        let infoArray: NSMutableArray = NSMutableArray()
        
        for group in self.grouplist {
            group.addresslist = [CustomerAddressItem]() 
            if self.custlevel == "" || self.custlevel == group.level {
                var dictionary: NSArray = (group as CustomerAddressGroupItem).addresslist
                let sectionInfo = CustomerSectionInfo()
                sectionInfo.group = group as CustomerAddressGroupItem
                sectionInfo.headerView.HeaderOpen = false
                
                infoArray.addObject(sectionInfo)
            }
            
            
            for item in self.itemlist{
                if group.name == item.group && (self.custlevel == "" || self.custlevel == item.custlevel) {
                    //println(self.custlevel)
                    group.addresslist.append(item)
                }
            }   
            
        }
        
        for arr in infoArray{
            let obj = arr as! CustomerSectionInfo
            if obj.group.name == "基金公司投资总监（潜在）" {
                //print("qqqqqqqqqqqqqqqqq\(obj.group.addresslist.count)")
            }
        
        }
        
        self.sectionInfoArray = infoArray
        //print("============================>> End Compute")
        self.tableView.reloadData()
        /*
        for group in self.grouplist{
            for item in self.itemlist{
                if group.name == item.group && (self.custlevel == "" || self.custlevel == item.custlevel) {
                    //println(self.custlevel)
                    group.addresslist.append(item)
                }
            }   
        }
*/
        
        /*
        for item in self.itemlist{
            
            for group in self.grouplist{
                
                if group.name == item.group && (self.custlevel == "" || self.custlevel == item.custlevel) {
                    //println(self.custlevel)
                    group.addresslist.append(item)
                    break
                }
            }   
        }
*/
        // 检查SectionInfoArray是否已被创建，如果已被创建，则检查组的数量是否匹配当前实际组的数量。通常情况下，您需要保持SectionInfo与组、单元格信息保持同步。如果扩展功能以让用户能够在表视图中编辑信息，那么需要在编辑操作中适当更新SectionInfo
        //println("reload data=================")
        //if self.sectionInfoArray == nil || self.sectionInfoArray.count != self.numberOfSectionsInTableView(self.tableView) {
        //println("load =====++++++++++++++")
        // 对于每个用户组来说，需要为每个单元格设立一个一致的SectionInfo对象
/*
        var infoArray: NSMutableArray = NSMutableArray()
        
        for group in self.grouplist {
            if self.custlevel == "" || self.custlevel == group.level {
                var dictionary: NSArray = (group as CustomerAddressGroupItem).addresslist
                var sectionInfo = CustomerSectionInfo()
                sectionInfo.group = group as CustomerAddressGroupItem
                sectionInfo.headerView.HeaderOpen = false
                
                infoArray.addObject(sectionInfo)
            }
        }
        self.sectionInfoArray = infoArray

*/
        
       
        
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        //println ("numberOfSectionsInTableView *************************\(self.sectionInfoArray.count)")
        if tableView == self.searchDisplayController?.searchResultsTableView {
            return 1
            //return self.grouplist.count
            
        } else {
            //return self.grouplist.count
            return self.sectionInfoArray.count
        }
        
    }
    
    // UITableViewDataSource Functions
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == self.searchDisplayController?.searchResultsTableView {
            //println("rows in section search bar")
            return self.filteredItemList.count
            
        } else {
            //println("rows in section normal ")
            
            let sectionInfo: CustomerSectionInfo = self.sectionInfoArray[section] as! CustomerSectionInfo
            let numStoriesInSection = sectionInfo.group.addresslist.count
            var sectionOpen = sectionInfo.headerView.HeaderOpen
            
            //println("---numberOfRowsInSection isopen\(sectionOpen) section:\(section)---count:\(numStoriesInSection)-  openindex\(opensectionindex)")
            
            return section == opensectionindex ? numStoriesInSection : 0
            
            //return sectionOpen ? numStoriesInSection : 0
            
            //return self.itemlist.count
            
        }
    }
    
    
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // 在tableview中查询一个条目，如果没有创建一个。
        
        //let FriendCellIdentifier = "FriendCellIdentifier"
        //var cell: FriendCell = tableView.dequeueReusableCellWithIdentifier(FriendCellIdentifier) as FriendCell
        
        
        
        //var cell:InnerAddressBookCell! = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as? InnerAddressBookCell
        
        // 从我们的糖果数组中获得相应的内容
        var item:CustomerAddressItem
        
        if tableView == self.searchDisplayController?.searchResultsTableView {
            //println("cell for search")
            
            item = filteredItemList[indexPath.row]
            
        } else {
            
            //println("cell for  normal")
            //item = self.itemlist[indexPath.row] as InnerAddressItem
            //println("---start cellForRowAtIndexPath section---\(indexPath.section)/\(sectionInfoArray.count)")
            
            let dept: CustomerAddressGroupItem = (self.sectionInfoArray[indexPath.section] as! CustomerSectionInfo).group
            //println("---\(indexPath.row)/\(dept.addresslist.count)---")
            item = dept.addresslist[indexPath.row] as CustomerAddressItem
            //cell.setFriend(cell.friend)
            
            
        }
        let cell:CustomerAddressBookCell! = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as? CustomerAddressBookCell
        
        
        cell.lblComp.text = item.comp
        cell.lblName.text = item.name
        cell.icon?.image = UIImage(named: "contactbook")
        
        cell.btnMobile.setTitle(item.mobile, forState:UIControlState.Normal)
        cell.btnLinetel.setTitle(item.linetel, forState:UIControlState.Normal)
        
        
        //点击事件
        cell.btnMobile.customerproperty1 = item.customerid
        cell.btnLinetel.customerproperty1 = item.customerid
        cell.btnMobile.addTarget(self, action: "onClick_Call:", forControlEvents: UIControlEvents.TouchUpInside)
        cell.btnLinetel.addTarget(self, action: "onClick_Call:", forControlEvents: UIControlEvents.TouchUpInside)
        
        
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        //println("---end cellForRowAtIndexPath section----")
        return cell
        
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // 返回指定的section header视图
        //println("---start tableview section----")
        //var tempcell:InnerAddressBookHeader = tableView.dequeueReusableHeaderFooterViewWithIdentifier("Header")
        //println(tempcell)
        let sectionHeaderView:CustomerAddressBookHeader = tableView.dequeueReusableHeaderFooterViewWithIdentifier("Header") as! CustomerAddressBookHeader
        
        //var temp:CGRect = sectionHeaderView.contentView.frame
        //temp.size.width = CGFloat(450)
        //sectionHeaderView.contentView.frame = temp
        
        let sectionInfo: CustomerSectionInfo = self.sectionInfoArray[section] as! CustomerSectionInfo
        //sectionHeaderView.frame.height = CGFloat(45)
        
        sectionInfo.headerView = sectionHeaderView
        sectionHeaderView.LblTitle.text = sectionInfo.group.name
        sectionHeaderView.section = section
        sectionHeaderView.delegate = self
        //println("---end tableview section----")
        return sectionHeaderView
    }
    
    func onClick_Call(sender:MKButton) {
        let num = sender.titleLabel?.text
        let customerid = sender.customerproperty1
        if num != nil {
            
            let btn_OK:PKButton = PKButton(title: "拨打",
                action: { (messageLabel, items) -> Bool in
                    let urlstr = "tel://\(num!)"
                    //print("=========click==========\(urlstr)")
                    let url1 = NSURL(string: urlstr)
                    UIApplication.sharedApplication().openURL(url1!)
                    
                    //记录客户拨打日志
                    let logItem = CustomerLogItem()
                    logItem.user = NSUserDefaults.standardUserDefaults().objectForKey("UserName") as! String
                    logItem.module = "CustomerAddressBook"
                    logItem.customerid = customerid
                    logItem.phonenumber = num
                    logItem.type = "2"
                    logItem.startdatetime = Util.getCurDateString()
                    logItem.enddatetime = ""
                    logItem.duration = NSUserDefaults.standardUserDefaults().objectForKey("CallDuration") as! String
              
                    
                    DBAdapter.shared.syncCustomerLogItem(logItem)
                    
                    
                    return true
                },
                fontColor: UIColor(red: 0, green: 0.55, blue: 0.9, alpha: 1.0),
                backgroundColor: nil)
            
            
            // call alert
            PKNotification.alert(
                title: "通话确认",
                message: "确认拨打电话:\(num!)?",
                items: [btn_OK],
                cancelButtonTitle: "取消",
                tintColor: nil)
        }
    }
    
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int){
        //print("selectedScopeButtonIndexDidChange scope = \(selectedScope)")
        /*
        if selectedScope == 1 {
        self.custlevel =  "重点人脉"
        }else if selectedScope == 2 {
        self.custlevel = "次要人脉"
        }else{
        self.custlevel = ""
        }
        println("filter scope = \(selectedScope) \(self.custlevel)")
        */
    }
    
    
    func filterContentForSearchText(searchText: String) {
        
        // 使用过滤方法过滤数组 陈陈
        //println("filterContentForSearchText = \(searchText)  \(self.custlevel)")
        /*
        self.filteredItemList = self.itemlist.filter({( customerAddressItem: CustomerAddressItem) -> Bool in
        
        //let categoryMatch = (scope == "All") || (innerAddressItem.dept == scope)
        let stringMatch = customerAddressItem.query.rangeOfString(searchText)
        
        //return categoryMatch && (stringMatch != nil)
        return (stringMatch != nil)
        
        })
        */
        
        self.filteredItemList = self.itemlist.filter({( customerAddressItem: CustomerAddressItem) -> Bool in
            
            //let categoryMatch = (scope == "All") || (innerAddressItem.dept == scope)
            let stringMatch = customerAddressItem.query.rangeOfString(searchText)
            let custLevelMatch = self.custlevel == "" || customerAddressItem.custlevel == self.custlevel
            //return categoryMatch && (stringMatch != nil)
            return (stringMatch != nil && custLevelMatch == true)
            
        })
        //self.ComputeAddressInfo(self.filteredItemList)
        //self.tableView.reloadData()
        
    }
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String?) -> Bool {
        
        //print("shouldReloadTableForSearchString")
        self.filterContentForSearchText(searchString!)
        return true
        
    }
    
    
    
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchScope searchOption: Int) -> Bool {
        //print("selectedScopeButtonIndexShouldChange scope = \(searchOption)")
        
        if searchOption == 1 {
            self.custlevel =  "重点人脉"
        }else if searchOption == 2 {
            self.custlevel = "次要人脉"
        }else{
            self.custlevel = ""
        }
        
        self.searchDisplayController!.searchBar.placeholder = self.custlevel == "" ? "全部" : self.custlevel
        
        //print(self.searchDisplayController!.searchBar.placeholder)
        
        if self.searchDisplayController!.searchBar.text != ""{
            self.filterContentForSearchText(self.searchDisplayController!.searchBar.text!)
            return true
        }else{
            self.opensectionindex = NSNotFound
            self.searchDisplayController?.setActive(false, animated: true)
            self.ComputeAddressInfo()
            return false
        }
        
    }
    
    /*
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
    self.performSegueWithIdentifier("Detail", sender: tableView)
    
    }
    */
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        //print("did select row at index path =\(indexPath)")
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let dept: CustomerAddressGroupItem = (self.sectionInfoArray[indexPath.section] as! CustomerSectionInfo).group
        //println("---\(indexPath.row)/\(dept.addresslist.count)---")
        let item = dept.addresslist[indexPath.row] as CustomerAddressItem
        
        let nextController:CustomerAddressDetail = CustomerAddressDetail()
        Message.shared.curCustomerAddressItem = item
        self.navigationController?.pushViewController(nextController,animated:false);
        
        
        
        //println("performSegueWithIdentifier")
        //self.performSegueWithIdentifier("Detail", sender: tableView)
        
    } 
    /*
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    //return CGFloat(DefaultRowHeight)
    //println("Default row height\(DefaultRowHeight)")
    return CGFloat(45)
    }
    */
    
    func customerAddressBookHeader(customerAddressBookHeader: CustomerAddressBookHeader, sectionOpened: Int) {
        //println("++++++section open+++++++++\(sectionOpened)")
        var sectionInfo: CustomerSectionInfo = self.sectionInfoArray[sectionOpened] as! CustomerSectionInfo
        sectionInfo.headerView.HeaderOpen = true
        
        if self.preopenindex != NSNotFound{
            var preSectionInfo: CustomerSectionInfo = self.sectionInfoArray[preopenindex] as! CustomerSectionInfo
            preSectionInfo.headerView.ImgNarrow.image = UIImage(named:"narrow_right")
        }
        sectionInfo.headerView.ImgNarrow.image = UIImage(named:"narrow_down")
        
        
        //创建一个包含单元格索引路径的数组来实现插入单元格的操作：这些路径对应当前节的每个单元格
        var countOfRowsToInsert = sectionInfo.group.addresslist.count
        //var indexPathsToInsert = NSMutableArray()
        var indexPathsToInsert:[NSIndexPath] = []

        for (var i = 0; i < countOfRowsToInsert; i++) {
            indexPathsToInsert.append(NSIndexPath(forRow: i, inSection: sectionOpened))
        }
        
        // 创建一个包含单元格索引路径的数组来实现删除单元格的操作：这些路径对应之前打开的节的单元格
        //var indexPathsToDelete = NSMutableArray()
        var indexPathsToDelete:[NSIndexPath] = []
        var previousOpenSectionIndex = opensectionindex
        //var perviousOpenSectionIndex = preopenindex
        //println("本次打开的section\(sectionOpened)  上次打开的section\(opensectionindex)")
        if previousOpenSectionIndex != NSNotFound {
            var previousOpenSection: CustomerSectionInfo = self.sectionInfoArray[previousOpenSectionIndex] as! CustomerSectionInfo
            //println("will close \(previousOpenSectionIndex)")
            previousOpenSection.headerView.HeaderOpen = false
            previousOpenSection.headerView.toggleOpen(false)
            //previousOpenSection.headerView.toggleOpen(true)
            
            var countOfRowsToDelete = previousOpenSection.group.addresslist.count
            for (var i = 0; i < countOfRowsToDelete; i++) {
                indexPathsToDelete.append(NSIndexPath(forRow: i, inSection: previousOpenSectionIndex))
            }
        }
        
        // 设计动画，以便让表格的打开和关闭拥有一个流畅的效果
        var insertAnimation: UITableViewRowAnimation
        var deleteAnimation: UITableViewRowAnimation
        if previousOpenSectionIndex == NSNotFound || sectionOpened < previousOpenSectionIndex {
            insertAnimation = UITableViewRowAnimation.Fade
            deleteAnimation = UITableViewRowAnimation.Fade
        }else{
            insertAnimation = UITableViewRowAnimation.Fade
            deleteAnimation = UITableViewRowAnimation.Fade
        }
        
        // 应用单元格的更新
        self.tableView.beginUpdates()
        
        //println("delete \(indexPathsToDelete) == insert\(indexPathsToInsert)")
        self.tableView.deleteRowsAtIndexPaths(indexPathsToDelete, withRowAnimation: deleteAnimation)
        self.tableView.insertRowsAtIndexPaths(indexPathsToInsert, withRowAnimation: insertAnimation)
        opensectionindex = sectionOpened
        
        self.tableView.endUpdates()
        
        self.preopenindex = sectionOpened  //2015-04-04 本次打开之后 将当前setion记录为上次打开的section
    }
    
    func customerAddressBookHeader(customerAddressBookHeader: CustomerAddressBookHeader, sectionClosed: Int) {
        //println("-----------section close------------")
        // 在表格关闭的时候，创建一个包含单元格索引路径的数组，接下来从表格中删除这些行
        var sectionInfo: CustomerSectionInfo = self.sectionInfoArray[sectionClosed] as! CustomerSectionInfo
        sectionInfo.headerView.HeaderOpen = false
        sectionInfo.headerView.ImgNarrow.image = UIImage(named:"narrow_right")
        opensectionindex = NSNotFound
        
        var countOfRowsToDelete = self.tableView.numberOfRowsInSection(sectionClosed)
        
        if countOfRowsToDelete > 0 {
            //var indexPathsToDelete = NSMutableArray()
            var indexPathsToDelete:[NSIndexPath] = []
            for (var i = 0; i < countOfRowsToDelete; i++) {
                indexPathsToDelete.append(NSIndexPath(forRow: i, inSection: sectionClosed))
            }
            self.tableView.beginUpdates()
            self.tableView.deleteRowsAtIndexPaths(indexPathsToDelete, withRowAnimation: UITableViewRowAnimation.Fade)
            self.tableView.endUpdates()
        }
        //opensectionindex = NSNotFound
        
        self.preopenindex = NSNotFound
    }
    /*
    //没有story board 所以没有seque
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
    println("prepareForSeque \(segue.identifier)")
    if segue.identifier == "Detail" {
    
    let candyDetailViewController = segue.destinationViewController as UIViewController
    
    if sender as UITableView == self.searchDisplayController!.searchResultsTableView {
    
    let indexPath = self.searchDisplayController!.searchResultsTableView.indexPathForSelectedRow()!
    
    let destinationTitle = self.filteredItemList[indexPath.row].name
    
    candyDetailViewController.title = destinationTitle
    
    } else {
    
    let indexPath = self.tableView.indexPathForSelectedRow()!
    
    let destinationTitle = self.itemlist[indexPath.row].name
    
    candyDetailViewController.title = destinationTitle
    
    }
    
    }
    
    }
    */
    
}
