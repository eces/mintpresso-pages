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

import models.{User, Key}
import play.api.libs.concurrent.Execution.Implicits._

object Users extends Controller with Secured {
  def signin = Action { implicit request =>
    val form = Form( tuple( "email" -> Forms.email, "password" -> nonEmptyText ) )
    form.bindFromRequest.fold (
      formWithErrors => Ok("form.empty"),
      values => {
        val (e, p) = values

        Async {
          Mintpresso(s"/user/${e}").get map { r1 =>
            if(r1.status == 200){
              val u = User( r1.json )
              u.password match {
                case "reset" => {
                  val time = new java.util.Date().getTime + 600*1000
                  val code = Crypto.encryptAES(u.no + "__MINT__" + u.email + "__MINT__" + time).toString
                  val codeUrl = routes.Application.changePassword(Some(code)).absoluteURL()
                  import actors._
                  Notification.email ! NewPasswordMail(u.name, u.id, codeUrl)
                  Created("reset.email.sent")
                }
                case x if x == Crypto.sign(p) => {
                  val url = u.email.replaceAll("[@.#]", "-")

                  Accepted(url).withSession(
                    "no" -> u.no.toString,
                    "email" -> u.email,
                    "name" -> u.name,
                    "url" -> url
                    // "phone" -> u.phone,
                    // "verified" -> u.verified,
                    // "testmode" -> u.testmode,
                    // "orderLimit" -> u.orderLimit,
                    // "rateLimit" -> u.rateLimit,
                    // "rateRemaining" -> u.rateRemaining,
                  )
                }
                case _ =>
                  Ok("user.invalid.password")
              }
            }else{
              Ok("user.invalid.email")
            }
          }
        }
      }
    )    
  }

  def signout = Action { implicit request =>
    Redirect(routes.Application.index).withNewSession
  }

  def signup = Action { implicit request =>
    val form = Form( tuple( "username" -> nonEmptyText, "email" -> Forms.email, "password" -> nonEmptyText ) )
    form.bindFromRequest.fold (
      formWithErrors => Ok("form.empty.invlid"),
      values => {
        val (u, e, p) = values

        Async {
          Mintpresso(s"/user/${e}").get map { r1 =>
            if(r1.status == 404){
              Async {
                Mintpresso(s"/user").withConnection { conn =>
                  val user = User.Empty(0)
                  user.id = e
                  user.email = e
                  user.password = Crypto.sign(p)
                  user.name = u
                  conn.post(user.toTypedJson)
                }.map { r2 =>
                  if(r2.status == 201){
                    val createdUser = User(r2.json)
                    val key = new Key("", 0L, List("*"), List(""), List("read_model", "search_model", "create_model", "update_model", "delete_model", "search_status", "create_status", "delete_status", "manage_order", "manage_pickup"))
                    Async {
                      Mintpresso(s"/key") withConnection { conn =>
                        conn.post(key.toTypedJson) map { r1 =>
                          if(r1.status == 201){
                            val createdKey = Key(r1.json)
                            createdKey.id = "secret__" + Crypto.encryptAES(createdUser.no + " " + createdKey.no)
                            Async {
                              Mintpresso(s"/user/${createdUser.no}/issue/key/${createdKey.no}").post map { r2 =>
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
                  }else{
                    Ok("try.again")
                  }
                }
              }
            }else{
              Ok("email.duplicate")
            }
          }
        }
      }
    )    
  }

  def findPassword(email: Option[String]) = Action { implicit request =>
    email.map { e =>
      Async {
        Mintpresso(s"/user/${e}").get map { r1 =>
          if(r1.status == 200){
            val u = User( r1.json )
            val time = new java.util.Date().getTime + 600*1000
            val code = Crypto.encryptAES(u.no + "__MINT__" + u.email + "__MINT__" + time).toString
            val codeUrl = routes.Application.changePassword(Some(code)).absoluteURL()
            import actors._
            Notification.email ! NewPasswordMail(u.name, u.id, codeUrl)
            Redirect(routes.Application.signin).flashing(
              "success" -> Messages("reset.email.sent.basic"),
              "retry" -> "true"
            )
          }else{
            Redirect(routes.Application.signin).flashing(
              "error" -> Messages("user.invalid.email"),
              "retry" -> "true"
            )
          }
        }
      }
    } getOrElse {
      Redirect(routes.Application.signin).flashing(
        "error" -> Messages("user.invalid.email"),
        "retry" -> "true"
      )
    }
  }

  def changePassword = Action { implicit request =>
    val form = Form( tuple( "code" -> nonEmptyText, "email" -> nonEmptyText, "password" -> nonEmptyText ) )
    form.bindFromRequest.fold (
      formWithErrors => {
        println(formWithErrors)
        Redirect(routes.Application.signin).flashing(
          "error" -> Messages("reset.fail"),
          "retry" -> "true"
        )
      },
      values => {
        val (c, e, p) = values

        val parts = Crypto.decryptAES(c).split("__MINT__")
        val no = parts(0)
        val email = parts(1)
        val time = parts(2)
        if(email != e){
          Redirect(routes.Application.changePassword(Some(c))).flashing(
            "error" -> Messages("form.empty.invalid"),
            "retry" -> "true"
          )  
        }else{
          if(time.toLong < new java.util.Date().getTime){
            Redirect(routes.Application.changePassword(Some(c))).flashing(
              "error" -> Messages("code.expired"),
              "retry" -> "true"
            ) 
          }else{
            Async {
              Mintpresso(s"/user/${no}").get map { r1 =>
                if(r1.status == 200){
                  val user = User(r1.json)
                  if(user.email != e){
                    Redirect(routes.Application.changePassword(Some(c))).flashing(
                      "error" -> Messages("form.empty.invalid"),
                      "retry" -> "true"
                    )       
                  }else{
                    user.password = Crypto.sign(p)
                    Async {
                      Mintpresso(s"/key/${no}").withConnection { conn =>
                        conn.put(user.toTypedJson)
                      } map { r2 =>
                        if(r2.status == 200 || r2.status == 201){
                          Redirect(routes.Application.signin).flashing(
                            "success" -> Messages("reset.done"),
                            "retry" -> "true"
                          )
                        }else{
                          Redirect(routes.Application.changePassword(Some(c))).flashing(
                            "error" -> Messages("apply.fail"),
                            "retry" -> "true"
                          )        
                        }
                      }
                    }
                  }
                }else{
                  Redirect(routes.Application.changePassword(Some(c))).flashing(
                    "error" -> Messages("reset.code.invalid"),
                    "retry" -> "true"
                  )
                }
              }
            }
          }
        }
      }
    )    
  }
}