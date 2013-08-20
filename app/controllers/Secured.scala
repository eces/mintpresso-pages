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
      request.session.get("email").getOrElse(""),
      request.session.get("name").getOrElse(""),
      request.session.get("url").getOrElse("")
    )
  }
  def getOptionUser(implicit request: RequestHeader): Option[User] = {
    request.session.get("no").map { no =>
      Some(getUser)
    } getOrElse {
      None
    }
  }
  def signed(implicit request: RequestHeader): Boolean = {
  	request.session.get("no").map { no =>
  	  true
  	} getOrElse {
  	  false
  	}
  }
  def Signed(f: Request[AnyContent] => User => Result) = Action { implicit request =>
    if(signed){
      f(request)(getUser)
    }else{
      Results.Redirect(routes.Application.signin).flashing(
        "msg" -> "Permission required.",
        "redirect_url" -> request.path
      )
    }
  }

  def SignedUrl(url: String)(f: Request[AnyContent] => Result) = Action { implicit request =>
    if(getUser.url == url){
      f(request)
    }else{
      Results.Redirect(routes.Application.signin).flashing(
        "msg" -> "Permission required.",
        "redirect_url" -> request.path,
        "account_change" -> "true"
      )
    }
  }

}