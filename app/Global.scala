import play.api._
import play.api.mvc._
import play.api.mvc.Results._
import play.api.libs.concurrent._
import play.api.Play.current

object Global extends GlobalSettings {

  override def onStart(app: Application) {
    // val f = new java.io.File( System.getProperty("user.home") + '/' + Play.configuration.getString("file.directory").getOrElse("mintpresso_files") )
    // if(!f.exists){
    //   if(f.mkdir()){
    //     Logger.info(f.toString)
    //     Logger.info("File directory created.")
    //   }
    // }
  }
  
  override def onStop(app: Application) {
    // Logger.info("Application shutdown...")
  }

  override def onError(request: RequestHeader, ex: Throwable) = {
    Results.Ok(play.api.libs.json.Json.obj("message" -> "error.500", "error" -> ex.getMessage)).as("application/json")
  }

  override def onHandlerNotFound(request: RequestHeader): Result = {
    Results.Ok(views.html.error404()(request, request.flash))
  }

  override def onBadRequest(request: RequestHeader, error: String) = {
    Results.Ok(play.api.libs.json.Json.obj("message" -> "error.400", "error" -> error)).as("application/json")
  }
}