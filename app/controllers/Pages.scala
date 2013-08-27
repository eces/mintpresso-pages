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
                "name" -> "create_model",
                "value" -> scopes.contains("create_model")
              ),
              Json.obj(
                "name" -> "update_model",
                "value" -> scopes.contains("update_model")
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
                createdKey.id = (request.body \ "label").asOpt[String].getOrElse("") + "__" + Crypto.encryptAES(user.no + " " + createdKey.no)
                Async {
                  Mintpresso(s"/user/${user.no}/issue/key/${createdKey.no}").post map { r2 =>
                    if(r2.status == 201){
                      Async {
                        Mintpresso(s"/key/${createdKey.no}") withConnection { conn =>
                          conn.put(key.toTypedJson) map { r3 =>
                            if(r1.status == 201){
                              Created("apply.done")
                            }else{
                              Ok("apply.fail 3")
                            }
                          }
                        }
                      }
                    }else{
                      Ok("apply.fail 2")
                    }
                  }
                }
              }else{
                Ok("apply.fail 1")
              }
            }
          }
        }
      }
    } catch {
      case e: MalformedURLException =>
        e.printStackTrace
        Ok(Json.obj("message" -> "url.invalid", "error" -> e.getMessage))
      case e: UnknownHostException =>
        e.printStackTrace
        Ok(Json.obj("message" -> "host.unavailable", "error" -> e.getMessage))
      case e: Exception =>
        e.printStackTrace
        Ok(Json.obj("message" -> "error.500", "error" -> e.getMessage))
    }
  }
  def accountApiKeyDelete(url: String, no: Long) = JsonAction(url) { implicit request => user =>
    Async {
      Mintpresso(s"/key/${key.no}").delete map { r1 =>
        if(r1.status == 201){
          Created("apply.done")
        }else{
          Ok("apply.fail")
        }
      }
    }
  }
  def collect(url: String, path: String) = TODO
  def order(url: String, path: String) = TODO
  def pickup(url: String, path: String) = TODO
  def support(url: String, path: String) = TODO
}