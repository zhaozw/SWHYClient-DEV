//
//  Config.swift
//  SWHY_Moblie
//
//  Created by sunny on 3/19/15.
//  Copyright (c) 2015 DY-INFO. All rights reserved.
//

import Foundation
class Config{

    struct RequestTag { 
        static let DoLogin = "DoLogin"
        static let GetMainMenu = "GetMainMenu"
        static let GetInnerAddressBook = "GetInnerAddressBook"
        static let GetInnerAddressBook_Dept = "GetInnerAddressBook_Dept"
        
        static let GetCustomerAddressBook = "GetCustomerAddressBook"
        static let GetCustomerAddressBook_Group = "GetCustomerAddressBook_Group"
        
        static let WebViewPreGet = "WebViewPreGet"
        
        static let PostAccessLog = "PostAccessLog"
        static let PostCustomerLog = "PostCustomerLog"
        static let GetParameter_CallDuration = "GetParameter_CallDuration"
        static let PostUploadAudioFile = "PostUploadAudioFile"
        static let GetWeiXinToken = "GetWeiXinToken"
        static let PostAudioTopic = "PostAudioTopic"
        static let GetPersonInfoByAD = "GetPersonInfoByAD"
    } 

    struct NotifyTag {
        static let RevokeSyncAddressbook = "RevokeSyncAddressbook"
        static let RevokeRemoveAddressbook = "RevokeRemoveAddressbook"
    }
    
    
    struct Encoding {
        static let GB2312 = CFStringEncodings.GB_18030_2000.rawValue
        static let UTF8 = NSUTF8StringEncoding
    }
    
    struct URL {
        static let BaseURL = "http://swinbak.swsresearch.net"
        static let Login = "http://swinbak.swsresearch.net/Mobile/mobileInterface.nsf/ag_checkMobile?Openagent"
        //static let ToDoList = "http://swinbak.swsresearch.net/mobile/mobileflow.nsf/fm_workflowplatform?openform"
        static let MainMenuList = "http://swinbak.swsresearch.net/Mobile/mobileInterface.nsf/fm_showMobileHP_ios?readForm"
        static let InnerAddressBook = "http://swinbak.swsresearch.net/Portal/SysBase/SysUserInfo.nsf/fm_allPersonXML?readform"
        static let InnerAddressBook_Dept = "http://swinbak.swsresearch.net/portal/SysBase/SysAppReg.nsf/fm_allDeptXML?readform"
        
        static let CustomerAddressBook = "http://swinbak.swsresearch.net/mobile/customerinfo.nsf/GetCustomerInfoByUserName?openagent"
        static let CustomerAddressBook_Group = "http://swinbak.swsresearch.net/mobile/customerinfo.nsf/GetGroupInfoByUserName?openagent"
        
        static let PostAccessLog = "http://swinbak.swsresearch.net/mobile/Log.nsf/DoPostAccessLog?openagent"
        static let PostCustomerLog = "http://swinbak.swsresearch.net/mobile/Log.nsf/DoPostCustomerLog?openagent"
        
        static let GetParameter_CallDuration = "http://swinbak.swsresearch.net/Mobile/mobileInterface.nsf/ag_getparameter?Openagent&key=IOS-Call-Duration-Default"
        //static let PostUploadFile = "http://192.168.1.106/audio/uploadhandler.ashx"
        static let PostUploadAudioFile = "http://download.swsresearch.net/audio/uploadhandler.ashx"
        
        
        static let GetWeiXinToken = "http://202.109.73.185/swhyweixin/gettoken.ashx?appid=swhyapp&secret=weiwei"
        static let PostAudioTopic = "http://202.109.73.185/swhyweixin/gentopic.ashx?token="
        static let AudioBaseURL = "http://download.swsresearch.net/audio/audiofile/"
        static let ViewWeiXinReport = "http://wxweb.swsresearch.com/report/getDetailReportInfo.do?reportType=2&reportId="
        
        static let GetPersonInfoByAD = "http://swinbak.swsresearch.net/Portal/SysBase/SysUserInfo.nsf/ag_getPersonInfoByAD?openagent&ReturnField=txtEmployeeID&AD="
        //ReturnField是要返回的字段 可更改   AD是传入的AD账号  注意参数大小写
    }
    struct Net {
        static let Domain = "swsresearch"
        static let ClientType = "ios"
    }
    
    struct UI {
        static let Title = "申万宏源证券研究所"
        static let PreNavItem = "< 返回"
        
    }
    
    struct TableName {
        static let MainMenuList = "MainMenuList"
        static let InnerAddressList = "InnerAddressList"
        static let InnerAddressDeptList = "InnerAddressDeptList"
        
        static let CustomerAddressList = "CustomerAddressList"
        static let CustomerAddressGroupList = "CustomerAddressGroupList"
        
        static let AccessLogList = "AccessLogList"
        static let CustomerLogList = "CustomerLogList"
    }
    
    struct AddressBook {
        static let SyncAddressBookGroupName = "所内通讯录"
    }

}