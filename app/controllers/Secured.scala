package controllers

import play.api._
import play.api.mvc._
import play.api.data.Forms._
import play.api.data._
import play.api.Play.current
import play.api.libs._

import models.User

trait Secured {
  def getUser(implicit request: RequestHeader): User = {
    User(
      request.session.get("no").getOrElse("0").toLong,
      request.session.get("id").getOrElse(""),
      request.session.get("email").getOrElse(""),
      request.session.get("name").getOrElse("")
    )
  }
  def getOptionUser(implicit request: RequestHeader): Option[User] = {
    request.session.get("id").map { id =>
      Some(getUser)
    } getOrElse {
      None
    }
  }
  def signed(implicit request: RequestHeader): Boolean = {
  	request.session.get("id").map { id =>
  	  true
  	} getOrElse {
  	  false
  	}
  }
  // def Signed(f: Request[AnyContent] => Result) = Action { implicit request =>
  //   if(authenticated){
  //     f(request)
  //   }else{
  //     Results.Redirect(routes.Application.login).flashing(
  //       "msg" -> "해당 링크에 들어가려면 로그인 인증이 필요합니다.",
  //       "redirect_url" -> request.path
  //     )
  //   }
  // }

  // def SignedAccount(accessId: Int)(f: Request[AnyContent] => Result) = Action { implicit request =>
  //   if(getId == accessId){
  //     f(request)
  //   }else{
  //     Results.Redirect(routes.Application.login).flashing(
  //       "msg" -> "해당 링크에 들어가려면 로그인 인증이 필요합니다.",
  //       "redirect_url" -> request.path,
  //       "account_change" -> "true"
  //     )
  //   }
  // }

}