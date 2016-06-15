//
//  ValiantZip.swift
//  unzip
//
//  Created by xiangwenwen on 15/11/12.
//  Copyright © 2015年 xiangwenwen. All rights reserved.
//

import Foundation

typealias LHMCheckingVersionCompletion = (error:NSError?,willUpdateTable:NSArray) -> Void
typealias LHMEmptyCallback = (Void)->Void
typealias LHMErrorCallback = (error:NSError?)->Void
typealias LHMModuleCallback = (fetchModule:ValiantFetchModule,error:NSError?) ->Void

private let cacheDirPath:NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as NSString
private let docDirPath:NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as NSString
private let defaultLeJiaYuanWebViewDir:NSString = docDirPath.stringByAppendingPathComponent("ljyWebViewContainer") as NSString
private let defaultLeJiaYuanDownloadDir:String = cacheDirPath.stringByAppendingPathComponent("ljyDownloadZip")
private let defailtLeJiaYuanVersionInfo:String = defaultLeJiaYuanWebViewDir.stringByAppendingString("/LHM-Zip-Config.plist")

/**
 *  内部使用的Error类型
 *  
 *  标注错误的行数，错误上下文
 */

protocol ValiantContextError : ErrorType {
    mutating func addContext<T>(type: T.Type)
}

protocol ValiantContextualizable {}

extension ValiantContextualizable {
    func addContext(var error: ValiantContextError) -> ValiantContextError {
        error.addContext(self.dynamicType)
        print("ContextError:\(error)\r\n")
        return error
    }
}

struct ValiantError:ValiantContextError {
    var source : String
    let reason : String
    init(reason: String, file: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
        self.reason = reason
        self.source = "\(file):\(function):\(line)"
    }
    mutating func addContext<T>(type: T.Type) {
        source += ":\(type)"
    }
}
// ValianError处理结束（包裹注释，请忽略）

extension NSData:ValiantContextualizable{
    /**
     NSData转换字典
     
     - returns: 返回一个JSON格式的字典
     */
    func JSONParse() throws -> NSDictionary{
        let JSON:NSDictionary
        do{
            JSON = try NSJSONSerialization.JSONObjectWithData(self, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
        }catch{
            throw addContext(ValiantError(reason: "NSData For NSDictionary"))
        }
        return JSON
    }
}

extension NSDictionary:ValiantContextualizable{
    /**
     字典转字符串
     
     - returns: <#return value description#>
     */
    func JSONStringify() throws ->String{
        let JSON:String
        do{
            let JSONData = try NSJSONSerialization.dataWithJSONObject(self, options: NSJSONWritingOptions.PrettyPrinted)
            JSON = String(data: JSONData, encoding: NSUTF8StringEncoding)!
        }catch{
            throw addContext(ValiantError(reason: "NSDictionary For String"))
        }
        return JSON
    }

}

extension NSArray{
    /**
     筛选取反
     
     - parameter callback: <#callback description#>
     
     - returns: <#return value description#>
     */
    func reject(callback:(obj:AnyObject)->Bool)->NSArray{
        return self.filteredArrayUsingPredicate( NSPredicate { (obj, bindings) -> Bool in
            return !callback(obj: obj)
        })
    }
}

//获取module描述
enum ValiantFetchModule:Int{
    case URLLocation   //可以成功获取本地地址
    case URLRequest   //可以成功获取远程地址
    case URLNone //获取本地和远程地址皆失败
}

/// 单例，管理中心
class ValiantCenterManager:NSObject,ValiantContextualizable{
    
    /// 管理中心单例
    class var sharedInstanceManager: ValiantCenterManager {
        struct centerStatic {
            static var onceToken:dispatch_once_t = 0
            static var instance:ValiantCenterManager? = nil
        }
        dispatch_once(&centerStatic.onceToken) { () -> Void in
            centerStatic.instance = ValiantCenterManager()
        }
        return centerStatic.instance!
    }
    
    //快速获取远程地址
    var fetchRunHTTP:[String:AnyObject?] = [:]
    //文件管理
    lazy var manager:NSFileManager = {
        return NSFileManager.defaultManager()
    }()
    
    /**
     检查远程版本信息，是否需要更新（接口一使用）
     
     - parameter completion: 检查完成之后的block，此block以切换到主线程中
     */
    func checkingZipUpdateVersion(completion:LHMCheckingVersionCompletion){
        
        //先请求从服务端请求接口获取版本信息数据
        
        //再从本地信息库中读取配置文件
        
        //与服务端版本信息进行比对
        
        //装载一个Update List Array
        
        //分发给completion 闭包
        let config:NSURLSessionConfiguration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        let session:NSURLSession = NSURLSession(configuration: config)
        let request:NSURLRequest = NSURLRequest(URL: NSURL(string: "")!)
        
        session.dataTaskWithRequest(request, completionHandler: {
            [unowned self] (data:NSData?,response:NSURLResponse?,error:NSError?) ->Void in
            
            //处理版本信息比对
            
        })
        
        if let version:NSArray = self.readingLocationVersionInfo(){
            print("version info \(version)")
        }else{
            
        }
        completion(error: nil, willUpdateTable: [["zip":"app-676e15c4873b99459fc62ee93cc22d0a.zip"]] as NSArray)
    }
    
    /**
     检查远程单个module配置信息（接口二使用）
     
     - parameter module:     本地HTML5包标识名
     - parameter url:        本地HTML5地址目标
     - parameter completion: 处理之后的block，此block以切换到主线程中
     */
    func checkingModuleConfig(module:String,url:String,completion:LHMModuleCallback){
        //当用户点击某个模块的时候，请求接口二，判断使用本地还是远程HTTP
        let config:NSURLSessionConfiguration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        let session:NSURLSession = NSURLSession(configuration: config)
        let request:NSURLRequest = NSURLRequest(URL: NSURL(string: url)!)
        session.dataTaskWithRequest(request, completionHandler: {
            [unowned self ](data:NSData?,response:NSURLResponse?,error:NSError?) -> Void in
            var load:ValiantFetchModule = .URLLocation
            if (error == nil){
                if let responseData:NSData = data{
                    do{
                        let handlerJson:NSDictionary = try responseData.JSONParse()
                        print("module配置信息 --- > \(handlerJson)")
                        if (self.fetchRunHTTP[module] != nil){
                            self.fetchRunHTTP.removeValueForKey(module)
                        }
                        self.fetchRunHTTP.updateValue(handlerJson["url"], forKey: module)
                        load = ValiantFetchModule.URLRequest
                    }catch{
                        self.addContext(ValiantError(reason: "检查远程单个module配置信息数据转换JSON出错"))
                    }
                }
            }
            //回调到主线程处理
            dispatch_async(dispatch_get_main_queue(), {
                completion(fetchModule: load, error: error)
            })
        })
    }

    /**
     解析zip包信息
     
     - parameter pathName: zip包名
     
     - returns: 返回一个字典
     */
    func extname(pathName:String) -> NSDictionary?{
        print("传入的是.zip包？ ---> \(pathName.hasSuffix(".zip"))")
        if pathName.hasSuffix(".zip"){
            if let pathArray:Array = pathName.characters.split(Character("-")){
                let projectName:String = String(pathArray.first!)
                var zipChar:String = String(pathArray.last!)
                zipChar.removeRange(Range(start: zipChar.characters.indexOf(".")!, end: zipChar.characters.endIndex))
                return ["name":projectName,"md5":zipChar] as NSDictionary
            }
        }
        return nil
    }
    
    /**
     清除已经下载的zip
     
     - parameter completion: 清除成功之后的block，此block以切换到主线程中
     */
    func cleanDownloadZip(completion:LHMErrorCallback){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            [unowned self] _ in
            var notifySignal:Int = 0
            var message:[String:AnyObject] = [:]
            var error:NSError?
            if let files:NSArray = self.manager.subpathsAtPath(defaultLeJiaYuanDownloadDir){
                for filePath in files{
                    let rmPath:String = defaultLeJiaYuanDownloadDir+"/d"+(filePath as! String)
                    if self.manager.fileExistsAtPath(rmPath){
                        do{
                            try self.manager.removeItemAtPath(rmPath)
                        }catch{
                            notifySignal++
                            message["name"] = rmPath
                            break;
                        }
                    }
                }
                dispatch_async(dispatch_get_main_queue(), {
                    if notifySignal == 0{
                        error = nil
                    }else{
                        error = NSError(domain: "LHM REMOVE ALL ZIP FILE", code: 500, userInfo: message)
                    }
                    completion(error: error)
                })
            }
        })
    }
    
    /**
     解压zip包
     
     - parameter fetchInfo: 待解压zip信息["name":"module标识","savePath":"存储的目标路径"]
     
     - returns: <#return value description#>
     */
    func unzipFileTo(fetchInfo:NSDictionary) ->Bool{
        let tagName:String = fetchInfo["name"] as! String
        let zipPath:String = fetchInfo["savePath"] as! String
        if let unToZipPath:String = self.fetchZipAddress(tagName){
            let isZipSuccess:Bool = SSZipArchive.unzipFileAtPath(zipPath, toDestination: unToZipPath)
            return isZipSuccess
        }
        return false
    }
    
    /**
     根据module以及page url获取本地运行地址
     
     - parameter module:  本地HTML5标识
     - parameter pageURL: 你需要运行的页面名
     
     - returns: <#return value description#>
     */
    func fetchContainerRun(module:String,runPageURL pageURL:String)->NSURL?{
        var container:NSURL? = nil
        if let page:String = self.fetchRunContainer(module, page: pageURL){
            container = NSURL(string: page)
        }
        return container
    }
    
    /**
     根据module获取在线地址
     
     - parameter module: 本地HTML5标识
     
     - returns: <#return value description#>
     */
    func fetchContainerRun(module:String)->NSURLRequest?{
        var container:NSURLRequest? = nil
        if let url:String = self.fetchRunHTTP[module] as? String{
            container = NSURLRequest(URL: NSURL(string: url)!)
        }
        return container
    }
    
    /**
     拼接文件在容器中的位置
     
     - parameter module: 本地HTML5标识
     - parameter source: 资源名
     
     - returns: <#return value description#>
     */
    func fetchContainerPath(module:String,sourcePath source:String)->String{
        let appPath:NSString = self.fetchZipAddress(module) as NSString
        return appPath.stringByAppendingPathComponent(source)
    }
    
    /**
     递归版查询目录下的某个文件，没事不要随便乱用，除非真的不知道完整路径（如果你都不知道，这不科学，真的）
     
     - parameter moduel: 本地HTML5标识
     - parameter source: 资源名
     
     - returns: <#return value description#>
     */
    func fetchContainerPath(moduel:String,recursivePath source:String) -> [String]{
        let appPath:NSString = self.fetchZipAddress(moduel) as NSString
        var sourcesPath:[String] = []
        var i:Int = 0
        if let sources:[String] = self.manager.subpathsAtPath(appPath as String){
            let count = sources.count
            if count > 0{
                while true{
                    let target:String = sources[i]
                    i++
                    if target.containsString(source){
                        sourcesPath.append(appPath.stringByAppendingPathComponent(target))
                        continue
                    }
                    if count == i{
                        break
                    }
                }
            }
        }
        return sourcesPath
    }
    
    private func fetchRunContainer(module:String,page:String)->String?{
        var container:String? = nil
        let appPath:NSString = self.fetchZipAddress(module) as NSString
        let isHtml = page.containsString(".html")
        if isHtml{
            container = appPath.stringByAppendingPathComponent(page)
        }
        return container
    }
    
    /**
     根据module获取放置zip包的位置
     
     - parameter module: <#module description#>
     
     - returns: <#return value description#>
     */
    private func fetchZipAddress(module:String) -> String{
        let appPath:NSString = defaultLeJiaYuanWebViewDir.stringByAppendingPathComponent(module) as NSString
        let isDir:Bool = self.manager.fileExistsAtPath(appPath as String)
        if !isDir{
            do{
                try self.manager.createDirectoryAtPath(appPath as String, withIntermediateDirectories: true, attributes: nil)
            }catch{
                self.addContext(ValiantError(reason: "创建module dir 失败 module name:\(module)"))
            }
        }
        return appPath as String
    }
    
    /**
     获取本地存储的配置信息
     
     - returns: <#return value description#>
     */
    private func readingLocationVersionInfo() -> NSArray?{
        if let version:NSArray =  NSArray(contentsOfFile: defailtLeJiaYuanVersionInfo){
            return version
        }
        return nil
    }
    
    /**
     保存远程配置数据到本地
     
     - parameter config: <#config description#>
     
     - returns: <#return value description#>
     */
    private func saveConfigPlist(config:NSArray) -> Bool?{
        var isWrite:Bool = true
        //写入文件
        if self.manager.fileExistsAtPath(defailtLeJiaYuanVersionInfo){
            //如果存在，先删除再写入
            do{
                try self.manager.removeItemAtPath(defailtLeJiaYuanVersionInfo)
                isWrite = config.writeToFile(defailtLeJiaYuanVersionInfo, atomically: true)
                return isWrite
            }catch{
                return false
            }
        }else{
            //写入
            isWrite = config.writeToFile(defailtLeJiaYuanVersionInfo, atomically: true)
            return isWrite
        }
    }
    
    /**
     远程数据格式转换
     
     - returns: <#return value description#>
     */
    private func formatter(completion:LHMEmptyCallback) -> NSArray?{
        
        return nil
    }
}

struct LHMFetchZipDataInfo {
    //下载任务URL
    let url:String
    //下载名称
    let name:String
    //下载MD5信息
    let md5:String
    //下载的zip存储地址
    let saveZipPath:String
    //用于保存断点数据
    var tempData:NSData?
    let id:String
    /**
     构造器
     
     - parameter name: <#name description#>
     - parameter url:  <#url description#>
     - parameter md5:  <#md5 description#>
     
     - returns: <#return value description#>
     */
    init(name:String,url:String,md5:String,id:Int){
        self.name = name
        self.url = url
        self.md5 = md5
        self.id = "zip_\(id)"
        let manager = NSFileManager.defaultManager()
        if !(manager.fileExistsAtPath(defaultLeJiaYuanDownloadDir)){
            do{
                try manager.createDirectoryAtPath(defaultLeJiaYuanDownloadDir, withIntermediateDirectories: true, attributes: nil)
            }catch{
                print("LHM create zip root path error #### name:\(self.name) md5:\(self.md5)")
                print("LHM create zip root Path #### path:\(defaultLeJiaYuanDownloadDir)")
            }
        }
        self.saveZipPath = (defaultLeJiaYuanDownloadDir as NSString).stringByAppendingPathComponent(self.name+".zip")
    }
}

@objc protocol ValiantFetchZipDelegate{
    optional func fetchZipDidFinishLoading(location:NSDictionary)->Void //队列中单个zip包下载完成之后调用
    optional func fetchZip(progress:Int,didReceiveSingleData location:NSDictionary)->Void //zip包下载进度
    optional func fetchZip(location:NSDictionary,didCompleteWithError error:NSError?)->Void //下载单个失败
}

class ValiantFetchZip:NSObject,NSURLSessionDownloadDelegate,ValiantContextualizable{
    let id:String
    //管理中心
    private lazy var valiantCenter:ValiantCenterManager = {
        return ValiantCenterManager.sharedInstanceManager
    }()
    private let fetchInfo:NSDictionary
    //一个下载单元结构体
    var info:LHMFetchZipDataInfo
    //下载进度
    var speed:[Int] = []
    //一个下载单元任务
    var task:NSURLSessionDownloadTask?
    //计时器
    var timer:NSTimer?
    //协议
    weak var delegate:ValiantFetchZipDelegate?
    //session
    var session:NSURLSession?
    var backgroundURLSessionFinishEvents:LHMEmptyCallback?
    
    init(info:LHMFetchZipDataInfo,delegate:ValiantFetchZipDelegate?) {
        //暂时传递一个nil
        self.info = info
        self.delegate = delegate
        self.id = "icepy_queue_\(info.id)"
        self.fetchInfo = ["name":self.info.name,"md5":self.info.md5,"savePath":self.info.saveZipPath]
        super.init()
        self.session = self.createBackgroundSession()
    }
    
    func startFetch(){
        if let url:NSURL = NSURL(string: self.info.url){
            let request:NSURLRequest = NSURLRequest(URL: url)
            task = session!.downloadTaskWithRequest(request)
        }
        task?.resume()
        timer?.invalidate()
    }
    
    //下载成功时
    
    @objc func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        timer?.invalidate()
        if let fromPath = location.path{
            if self.removeZipDir(){
                do{
                    try self.valiantCenter.manager.moveItemAtPath(fromPath, toPath: self.info.saveZipPath)
                    self.finishDownloadZipTask()
                }catch{
                    self.addContext(ValiantError(reason: "下载成功：\(self.id) 移动临时数据到保存目录错误：\(self.info.saveZipPath)"))
                }
            }
        }else{
            print("system return location.path error #### current id:\(self.id)")
        }
    }
    
    //下载失败时
    
    @objc func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if let err = error{
            self.delegate?.fetchZip?(self.fetchInfo, didCompleteWithError: err)
            self.overFetch()
        }
    }
    
    //下载进度
    
    @objc func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress:Int = Int((Float(totalBytesWritten) / Float(totalBytesExpectedToWrite))*100)
        self.speed.append(Int(bytesWritten))
        self.delegate?.fetchZip?(progress, didReceiveSingleData: self.fetchInfo)
        print(" self id:\(self.id) progress:\(progress) download zip name:\(fetchInfo["name"] as! String)-\(fetchInfo["md5"] as! String).zip")
    }
    
    //如果解除引用，系统会通知在这个delegate中
    @objc func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        
    }
    
    //创建普通session或后台session
    private func createBackgroundSession() -> NSURLSession{
        return NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: nil)
    }
    
    //暂停下载任务
    
    func pasueFetch(){
        if let task = self.task{
            if task.state == .Running{
                //如果任务还在运行当中，将数据存入临时tempData中
                task.cancelByProducingResumeData(){
                    [unowned self](data:NSData?) in
                    self.info.tempData = data
                    self.speed = []
                    self.task = nil
                    self.timer?.invalidate()
                }
            }
        }
    }
    
    //取消下载任务，当前实例的强引用依然由系统持用
    
    func cancelFetch(){
        //如果存在下载任务，先取消
        if let task = self.task{
            task.cancel()
            self.task = nil
        }
        //清空已经下载的数据信息
        self.info.tempData = nil
        self.speed = []
        self.timer?.invalidate()
    }
    
    //完全取消，解除系统对当前实例的强引用，并且释放内存
    
    func overFetch(){
        self.cancelFetch()
        self.session?.invalidateAndCancel()
    }
    
    //完成zip下载任务
    
    private func finishDownloadZipTask(){
        self.delegate?.fetchZipDidFinishLoading?(self.fetchInfo)
        self.overFetch()
    }
    
    /**
     计算X秒内写入的数据
     
     - returns: <#return value description#>
     */
    
    private func computeSeep() ->String{
        var complete = 0
        for data in speed{
            complete += data
        }
        speed = []
        return "\(complete/256)"
    }
    
    //删除单个zip包
    
    private func removeZipDir() -> Bool{
        let isExists:Bool = (self.valiantCenter.manager.fileExistsAtPath(self.info.saveZipPath))
        if isExists{
            do{
                try self.valiantCenter.manager.removeItemAtPath(self.info.saveZipPath)
            }catch{
                self.addContext(ValiantError(reason: "删除单个zip包错误，current id:\(self.id) remove path:\(self.info.saveZipPath)"))
                return false
            }
        }
        return true
    }
    
    deinit{
        //释放池
        print("ValiantFetchZip id:\(self.id) release memory")
    }
}