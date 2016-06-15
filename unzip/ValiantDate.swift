//
//  ValiantDate.swift
//  unzip
//
//  Created by xiangwenwen on 15/12/5.
//  Copyright © 2015年 xiangwenwen. All rights reserved.
//

import Foundation

class Date: NSObject {
    lazy var dateFormatter = {
        return NSDateFormatter()
    }()

    override init() {
        let location = NSLocale(localeIdentifier: "zh-CN")
        super.init()
        let timeString = "20110826134106"
        self.dateFormatter.locale = location
        self.dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let date:NSDate = self.dateFormatter.dateFromString(timeString)!
        print(date)
        
        
        let now = NSDate()
        print("现在的时间：\(now)")
        
        let perDay:NSTimeInterval = 24*60*60
        let tomorrow = NSDate(timeIntervalSinceNow: perDay)
        let _tomorrow = now.dateByAddingTimeInterval(perDay)
        print("明天的时间：\(tomorrow)")
        let yesterday = NSDate(timeIntervalSinceNow: -perDay)
        //增加时间间隔
        let _yesterday = now.dateByAddingTimeInterval(-perDay)
        print("昨天的时间：\(yesterday)")
        
        //比较时间，如果两个时间间隔小于一分钟，可认为在同一天
        if tomorrow.timeIntervalSinceDate(yesterday) < 60 {
            //相等
        }else{
            //不相等
        }
        //NSCalendar定义了不同的日历，包括佛教历，格里高利历等（这些都与系统提供的本地化设置相关）
        //let calendar = NSCalendar.currentCalendar()
        //let unitF = NSCalendarIdentifierChinese
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        let components = NSDateComponents()
        components.year = 2105
        components.month = 12
        components.day = 5
        
        let unitF:NSCalendarUnit = [NSCalendarUnit.Year,NSCalendarUnit.Month,NSCalendarUnit.Day,NSCalendarUnit.Hour,NSCalendarUnit.Minute,NSCalendarUnit.Second]
        let dateComponents:NSDateComponents? = calendar?.components(unitF, fromDate: now, toDate: yesterday, options: .MatchNextTimePreservingSmallerUnits)
        print("年：\(dateComponents?.year)")
        print("月：\(dateComponents?.month)")
        print("日：\(dateComponents?.day)")
        print("小时：\(dateComponents?.hour)")
        print("分钟：\(dateComponents?.minute)")
        print("秒：\(dateComponents?.second)")
    }
}