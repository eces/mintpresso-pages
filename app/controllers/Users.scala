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
import scala.util.{Try, Success, Failure}
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
              if( u.password == Crypto.sign(p) ){
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
              }else{
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
}