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

import models.User
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
                  val code = Crypto.encryptAES(u.no + "__MINT__" + u.email).toString
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
                    Created
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

  def changePassword = Action { implicit request =>
    val form = Form( tuple( "code" -> nonEmptyText, "email" -> nonEmptyText, "password" -> nonEmptyText ) )
    form.bindFromRequest.fold (
      formWithErrors => Redirect(routes.Application.signin).flashing(
        "error" -> Messages("reset.fail")
      ),
      values => {
        val (c, e, p) = values

        val parts = Crypto.decryptAES(c).split("__MINT__")
        val no = parts(0)
        val email = parts(1)
        if(email != e){
          Redirect(routes.Application.changePassword(Some(c))).flashing(
            "error" -> Messages("form.empty.invalid")
          )  
        }else{
          Async {
            Mintpresso(s"/user/${no}").get map { r1 =>
              if(r1.status == 200){
                val user = User(r1.json)
                if(user.email != e){
                  Redirect(routes.Application.changePassword(Some(c))).flashing(
                    "error" -> Messages("form.empty.invalid")
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
                          "msg" -> Messages("reset.done")
                        )
                      }else{
                        Redirect(routes.Application.changePassword(Some(c))).flashing(
                          "error" -> Messages("apply.fail")
                        )        
                      }
                    }
                  }
                }
              }else{
                Redirect(routes.Application.changePassword(Some(c))).flashing(
                  "error" -> Messages("reset.code.invalid")
                )
              }
            }
          }
        }
      }
    )    
  }
}