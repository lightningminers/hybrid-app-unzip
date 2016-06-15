//
//  ValiantFetchZipManager.swift
//  unzip
//
//  Created by xiangwenwen on 15/11/16.
//  Copyright © 2015年 xiangwenwen. All rights reserved.
//

import Foundation

typealias LHMFetchUnZipDidFinishLoading = (error:NSError?,location:NSDictionary) -> Void

@objc protocol ValiantFetchZipManagerDelegate{
    optional func managerUnZipDidFinishLoading(location:NSDictionary)->Void //解压成功
    optional func managerUnZipDidCompleteWithError(location:NSDictionary,error:NSError?)->Void //解压失败
    optional func managerZipDidFinishLoading()->Void  //队列中所有的zip包下载完成之后调用
}

private var date = Date()


class ValiantFetchZipManager: NSObject,ValiantFetchZipDelegate {
    
    private lazy var valiantCenter:ValiantCenterManager = {
        return ValiantCenterManager.sharedInstanceManager
    }()
    
    private var receive:LHMFetchUnZipDidFinishLoading?
    private var completion:LHMEmptyCallback?
    weak var delegate:ValiantFetchZipManagerDelegate?
    var fetchZipCount:Int = 0
    var notifySignal:Int = 0
    
    /**
     启动获取zip 协议版
     */
    func startFetchZip(){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            [unowned self] _ in
            self.checkingVersion()
        })
    }
    
    /**
     启动获取zip 闭包版 无法获取单个zip包进度
     
     - parameter receive:    接收单个zip下载完成
     - parameter completion: 所有的下载完成
     */
    func startFetchZip(receive:LHMFetchUnZipDidFinishLoading,completion:LHMEmptyCallback){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            [unowned self] _ in
            self.receive = receive
            self.completion = completion
            self.checkingVersion()
        })
    }
    
    /**
     下载错误时处理
     
     - parameter location: <#location description#>
     - parameter error:    <#error description#>
     */
    func fetchZip(location: NSDictionary, didCompleteWithError error: NSError?) {
        //zip 下载错误
        self.receive?(error: error, location: location)
    }
    
    /**
     下载完成时处理
     
     - parameter location: <#location description#>
     */
    func fetchZipDidFinishLoading(location: NSDictionary) {
        self.notifySignal++
        //解压相应的zip包到对应的容器
        let isZipSuccess = self.valiantCenter.unzipFileTo(location)
        if isZipSuccess{
            self.receive?(error: nil, location: location)
            self.delegate?.managerUnZipDidFinishLoading?(location)
        }else{
            let error:NSError = NSError(domain: "LHM MANAGER UN ZIP", code: 500, userInfo: nil)
            self.receive?(error: error, location: location)
            self.delegate?.managerUnZipDidCompleteWithError?(location, error: error)
        }
        if self.fetchZipCount == self.notifySignal{
            //告诉用户，已经全部下载完毕，并且切换到主线程中
            dispatch_async(dispatch_get_main_queue(), {
                [unowned self] _ in
                self.delegate?.managerZipDidFinishLoading?()
                self.completion?()
            })
        }
    }
    
    /**
     下载进度处理
     
     - parameter progress: <#progress description#>
     - parameter location: <#location description#>
     */
    func fetchZip(progress: Int, didReceiveSingleData location: NSDictionary) {
        
    }
    
    /**
     检查版本信息
     */
    private func checkingVersion(){
        self.valiantCenter.checkingZipUpdateVersion(){
            [unowned self](error:NSError?,willUpdateTable:NSArray) in
            //更新需要下载的zip 包数量
            self.fetchZipCount = willUpdateTable.count
            
            for (i,info) in willUpdateTable.enumerate(){
                self.downloadZipInfo(info as! NSDictionary, id: i+1)
            }
        }
    }
    
    /**
     启动下载zip包
     */
    private func downloadZipInfo(downloadInfo:NSDictionary,id:Int){
        let url:NSString = "http://7xka6b.dl1.z0.glb.clouddn.com/" as NSString
        if let extInfo:NSDictionary = self.valiantCenter.extname(downloadInfo["zip"] as! String){
            let info:LHMFetchZipDataInfo = LHMFetchZipDataInfo(name: extInfo["name"] as! String, url: url.stringByAppendingPathComponent(downloadInfo["zip"] as! String), md5: extInfo["md5"] as! String,id:id)
            let fetch = ValiantFetchZip(info: info, delegate: self)
            fetch.startFetch()
        }
    }
    
    deinit{
        //释放池
        print("ValiantFetchZipManager release memory")
    }
}