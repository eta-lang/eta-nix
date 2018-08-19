import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

class FindMavenDepends {
    public static void main(String[] args) throws IOException {
        String[] mavenDepends = System.getenv("mavenDepends").split(" ");
        for(String path : mavenDepends) {
            Files.walk(Paths.get(path))
                .filter(Files::isRegularFile)
                .forEach(System.out::println);
        }
    }
}
