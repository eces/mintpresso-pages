package controllers

import play.api._
import play.api.i18n.Messages
import play.api.mvc._
import play.api.data.Forms._
import play.api.data._
import play.api.Play.current
import play.api.libs._
import play.api.cache._
import play.api.libs.json._
import scala.concurrent._
import scala.concurrent.duration._
import play.api.libs.ws.Response
import play.api.libs.concurrent.Execution.Implicits._
import models.{Key}

object Pages extends Controller with Secured {
  def account(url: String, path: String) = SignedUrl(url) { implicit request => user =>
    Ok(views.html.pages.account())    
  }
  def accountUsage(url: String) = SignedUrl(url) { implicit request => user =>
    Ok(Json.obj())
  }
  def accountPlansAndBilling(url: String) = SignedUrl(url) { implicit request => user =>
    Ok(Json.obj())
  }
  def accountApiKey(url: String) = SignedUrl(url) { implicit request => user =>
    Async {
      Mintpresso(s"/user/${user.no}/issue/key").get map { r1 =>
        if(r1.status == 200){
          val keys = (r1.json \\ "$object")
          Ok( keys.foldLeft(Json.arr()) { (a, b) => 
            val scopes = (b \ "scope").as[List[String]]
            val nameAndTypeScope = Json.arr(
              Json.obj(
                "name" -> "read_model",
                "value" -> scopes.contains("read_model")
              ),
              Json.obj(
                "name" -> "search_model",
                "value" -> scopes.contains("search_model")
              ),
              Json.obj(
                "name" -> "create_model",
                "value" -> scopes.contains("create_model")
              ),
              Json.obj(
                "name" -> "update_model",
                "value" -> scopes.contains("update_model")
              ),
              Json.obj(
                "name" -> "delete_model",
                "value" -> scopes.contains("delete_model")
              ),
              Json.obj(
                "name" -> "search_status",
                "value" -> scopes.contains("search_status")
              ),
              Json.obj(
                "name" -> "create_status",
                "value" -> scopes.contains("create_status")
              ),
              Json.obj(
                "name" -> "delete_status",
                "value" -> scopes.contains("delete_status")
              ),
              Json.obj(
                "name" -> "manage_order",
                "value" -> scopes.contains("manage_order")
              ),
              Json.obj(
                "name" -> "manage_pickup",
                "value" -> scopes.contains("manage_pickup")
              )
              // ,
              // Json.obj(
              //   "name" -> "read_type",
              //   "value" -> scopes.contains("read_type")
              // ),
              // Json.obj(
              //   "name" -> "read_verb",
              //   "value" -> scopes.contains("read_verb")
              // )
            )
            val label = (b \ "$id").as[String].split("__")(0)
            val urls = (b \ "url").as[List[String]].foldLeft(Json.arr()) { (a, b) =>
              a.append( Json.obj(
                "value" -> b
              ))
            }
            a.append( b.as[JsObject] ++ Json.obj(
              "scope" -> nameAndTypeScope,
              "label" -> label,
              "url" -> urls
            )) 
          } )
        }else{
          Ok(Json.arr())
        }
      }
    }
  }
  def accountApiKeyUpdate(url: String) = JsonAction(url) { implicit request => user =>
    import java.net.{InetAddress, URL, MalformedURLException, UnknownHostException}
    try {
      var scope: List[String] = List()
      (request.body \ "scope").as[List[JsObject]].foreach { b =>
        if((b \ "value").as[Boolean]){
          scope :+= (b \ "name").as[String]
        }
      }
      var url: List[String] = List()
      (request.body \ "url").as[List[JsObject]].foreach { b =>
         url :+= (b \ "value").as[String]
      }
      var address: List[String] = List()
      url.foreach { item =>
        if(item != "*"){
          var query: InetAddress = InetAddress.getByName(new URL("http://"+item).getHost())
          var ip = query.getHostAddress()
          // add to address list
          address :+= (ip.toString)
        }
      }


      var j = request.body.as[JsObject] ++ Json.obj(
        "scope" -> scope,
        "url" -> url,
        "address" -> address
      )

      val key = Key(Json.obj("key" -> j))

      val label = (request.body \ "label").asOpt[String].getOrElse("").replace("__", "")
      if(key.id.length > 0){
        val parts = key.id.split("__")
        if(parts(0) != label){
          key.id = label + parts(1)
        }
      }

      if(key.no > 0){
        // update
        Async {
          Mintpresso(s"/key/${key.no}") withConnection { conn =>
            conn.put(key.toTypedJson) map { r1 =>
              if(r1.status == 201){
                Created("apply.done")
              }else{
                Ok("apply.fail")
              }
            }
          }
        }
      }else{
        // create new
        Async {
          Mintpresso(s"/key") withConnection { conn =>
            conn.post(key.toTypedJson) map { r1 =>
              if(r1.status == 201){
                val createdKey = Key(r1.json)
                createdKey.id = label + "__" + Crypto.encryptAES(user.no + " " + createdKey.no)
                Async {
                  Mintpresso(s"/user/${user.no}/issue/key/${createdKey.no}").post map { r2 =>
                    if(r2.status == 201){
                      Async {
                        Mintpresso(s"/key/${createdKey.no}") withConnection { conn =>
                          conn.put(createdKey.toTypedJson) map { r3 =>
                            if(r3.status == 201){
                              Created("apply.done")
                            }else{
                              // error
                              Ok("apply.fail")
                            }
                          }
                        }
                      }
                    }else{
                      // error
                      Ok("apply.fail")
                    }
                  }
                }
              }else{
                // error
                Ok("apply.fail")
              }
            }
          }
        }
      }
    } catch {
      case e: MalformedURLException =>
        e.printStackTrace
        Ok("url.invalid")
      case e: UnknownHostException =>
        e.printStackTrace
        // Ok(Json.obj("message" -> "host.unavailable", "error" -> e.getMessage))
        Ok("host.unavailable")
      case e: Exception =>
        e.printStackTrace
        // Ok(Json.obj("message" -> "error.500", "error" -> e.getMessage))
        Ok("error.500")
    }
  }
  def accountApiKeyDelete(url: String, no: Long) = SignedUrl(url) { implicit request => user =>
    Async {
      Mintpresso(s"/key/${no}").delete map { r1 =>
        if(r1.status == 203 || r1.status == 204){
          Created("delete.done")
        }else{
          Ok("delete.fail")
        }
      }
    }
  }
  def accountDeveloperConsole(url: String) = SignedUrl(url) { implicit request => user =>
    Async {
      Mintpresso(s"/user/${user.no}/log/request").get map { r1 =>
        if(r1.status == 200){
          Ok( (r1.json \\ "$object").foldLeft(Json.arr()){ (a, b) =>
            a.append(b)
          })
        }else{
          Ok(Json.arr())
        }
      }
    }
  }
  def collect(url: String, path: String) = SignedUrl(url) { implicit request => user =>
    Async {
      Mintpresso(s"/user/${user.no}/issue/key").get map { r1 =>
        if(r1.status == 200){
          val keys = (r1.json \\ "$object")
          keys.find( (a: JsValue) => (a \ "$id").as[String].startsWith("secret__") ) match {
            case Some(key) => Ok(views.html.pages.collect((key \ "$id").as[String]))
            case None => Ok(views.html.pages.collect(""))
          }
        }else{
          Ok(views.html.pages.collect(""))
        }
      }
    }
  }
  def collectSearch(url: String, path: String) = JsonAction(url) { implicit request => user =>
    Ok(Json.obj())
  }
  def collectImport(url: String) = SignedUrl(url) { implicit request => user =>
    Ok(Json.obj())
  }
  def collectImportUpload(url: String) = FormDataAction(url) { implicit request => user =>
    request.body.file("attachment").map { f =>
      import java.io.File
      val local = url + "." + java.util.UUID.randomUUID().toString
      val name = f.filename
      val contentType = f.contentType.getOrElse("application/octet-stream")
      val upload = new File(System.getProperty("user.home") + "/" + Play.configuration.getString("file.directory").getOrElse("mintpresso_files") + "/" + local)
      f.ref.moveTo(upload)
      val size = upload.length.toInt

      Async {
        Mintpresso("/file") withConnection { conn =>
          conn.post(Json.obj( "file" -> Json.obj(
            "name" -> name,
            "local" -> local,
            "contentType" -> contentType,
            "size" -> size,
            "user" -> user.no
          ))) map { r1 =>
            if(r1.status == 201){
              Redirect(routes.Pages.collectImport(url)).flashing(
                "success" -> "submit.done"
              )
            }else{
              Redirect(routes.Pages.collectImport(url)).flashing(
                "error" -> "submit.fail"
              )
            }
          }
        }
      }
    } getOrElse {
      Redirect(routes.Pages.collectImport(url)).flashing(
        "error" -> "upload.empty"
      )
    }
  }
  def collectExport(url: String) = SignedUrl(url) { implicit request => user =>
    Ok(Json.obj())
  }
  def order(url: String, path: String) = SignedUrl(url) { implicit request => user =>
    Async {
      Mintpresso(s"/user/${user.no}/issue/key").get map { r1 =>
        if(r1.status == 200){
          val keys = (r1.json \\ "$object")
          keys.find( (a: JsValue) => (a \ "$id").as[String].startsWith("secret__") ) match {
            case Some(key) => Ok(views.html.pages.order((key \ "$id").as[String]))
            case None => Ok(views.html.pages.order(""))
          }
        }else{
          Ok(views.html.pages.order(""))
        }
      }
    }
  }
  def orderStatus(url: String) = SignedUrl(url) { implicit request => user =>
    Async {
      Mintpresso(s"/user/${user.no}/request/order").get map { r1 =>
        if(r1.status == 200){
          Ok((r1.json \\ "$object").foldLeft(Json.arr()){ (a, b) =>
            a.append((b))
          })
        }else{
          Ok(Json.arr())
        }
      }
    }
  }
  def orderStatusStart(url: String, no: Long) = SignedUrl(url) { implicit request => user =>
    Async {
      Mintpresso(s"/order/${no}/prepare").get map { r1 =>
        r1.status match {
          case 202 => Accepted
          case 200 => Ok
          case 404 => NoContent
          case _ => BadRequest
        }
      }
    }
  }
  def orderStatusPause(url: String, no: Long) = SignedUrl(url) { implicit request => user =>
    Async {
      Mintpresso(s"/order/${no}/cancel").get map { r1 =>
        r1.status match {
          case 202 => Accepted
          case 200 => Ok
          case 404 => NoContent
          case _ => BadRequest
        }
      }
    }
  }
  def orderDelete(url: String, no: Long) = SignedUrl(url) { implicit request => user =>
    Ok
  }
  def orderAdd(url: String) = SignedUrl(url) { implicit request => user =>
    Ok(Json.obj())
  }
  def orderAddType(url: String) = SignedUrl(url) { implicit request => user =>
    Async {
      Mintpresso(s"/types/${user.no}").get map { r1 =>
        Ok(r1.json)
      }
    }
  }
  def orderAddVerb(url: String) = SignedUrl(url) { implicit request => user =>
    Async {
      Mintpresso(s"/verbs/${user.no}").get map { r1 =>
        Ok(r1.json)
      }
    }
  }
  def orderAddUpdate(url: String) = JsonAction(url) { implicit request => user =>
    val json = request.body.as[JsObject]
    Async {
      Mintpresso("/order").withConnection { conn =>
        conn.post(Json.obj("order" -> json))
      } map { r1 =>
        if(r1.status == 201){
          val orderNo = (r1.json \ "order" \ "$no").as[Long]
          Async {
            Mintpresso(s"/user/${user.no}/request/order/${orderNo}").post map { r2 =>
              if(r2.status == 201){
                Created("apply.done")
              }else{
                Logger.info(r1.body)
                Ok("apply.fail")        
              }
            }
          }
        }else{
          Logger.info(r1.body)
          Ok("apply.fail")
        }
      }
    }
  }
  def pickup(url: String, path: String) = SignedUrl(url) { implicit request => user =>
    Ok(views.html.pages.pickup(""))
  }
  def pickupList(url: String) = SignedUrl(url) { implicit request => user =>
    Async {
      Mintpresso(s"/user/${user.no}/request/pickup").get map { r1 =>
        if(r1.status == 200){
          Ok((r1.json \\ "$object").foldLeft(Json.arr()){ (a, b) =>
            a.append((b))
          })
        }else{
          Ok(Json.arr())
        }
      }
    }
  }
  def pickupAdd(url: String) = SignedUrl(url) { implicit request => user =>
    Async {
      Mintpresso(s"/user/${user.no}/request/order").get map { r1 =>
        if(r1.status == 200){
          Ok((r1.json \\ "$object").foldLeft(Json.arr()){ (a, b) =>
            a.append((b))
          })
        }else{
          Ok(Json.arr())
        }
      }
    }
  }
  def pickupAddUpdate(url: String) = JsonAction(url) { implicit request => user =>
    val json = request.body.as[JsObject]
    Async {
      Mintpresso("/pickup").withConnection { conn =>
        conn.post(Json.obj("pickup" -> json))
      } map { r1 =>
        if(r1.status == 201){
          val pickupNo = (r1.json \ "pickup" \ "$no").as[Long]
          Async {
            Mintpresso(s"/user/${user.no}/request/pickup/${pickupNo}").post map { r2 =>
              if(r2.status == 201){
                Async {
                  val orderNo = (json \ "orderNo").as[Long]
                  Mintpresso(s"/order/${orderNo}/callback/pickup/${pickupNo}").post map { r3 =>
                    if(r3.status == 201){
                      Created("apply.done")
                    }else{
                      Ok("apply.fail")        
                    }
                  }
                }
              }else{
                Logger.info(r1.body)
                Ok("apply.fail")        
              }
            }
          }
        }else{
          Logger.info(r1.body)
          Ok("apply.fail")
        }
      }
    }
  }
  def pickupDelete(url: String, no: Long) = SignedUrl(url) { implicit request => user =>
    Ok
  }
  def pickupListStart(url: String, no: Long) = SignedUrl(url) { implicit request => user =>
    Async {
      Mintpresso(s"/pickup/${no}/prepare").get map { r1 =>
        r1.status match {
          case 202 => Accepted
          case 200 => Ok
          case 404 => NoContent
          case _ => BadRequest
        }
      }
    }
  }
  def pickupListPause(url: String, no: Long) = SignedUrl(url) { implicit request => user =>
    Async {
      Mintpresso(s"/pickup/${no}/cancel").get map { r1 =>
        Logger.debug("cancel " + r1.body + r1.status)
        r1.status match {
          case 202 => Accepted
          case 200 => Ok
          case 404 => NoContent
          case _ => BadRequest
        }
      }
    }
  }
  def support(url: String, path: String) = SignedUrl(url) { implicit request => user =>
    Ok(views.html.pages.support(""))
  }
}