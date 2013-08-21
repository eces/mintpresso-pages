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

object Pages extends Controller with Secured {
  def index(url: String) = SignedUrl(url) { implicit request =>
    Ok(views.html.pages.index())    
  }
}